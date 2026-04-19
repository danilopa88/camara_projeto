import requests
import json
import os
from datetime import datetime
from google.cloud import storage
import functions_framework
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env local para testes fora do GCP
load_dotenv()

# Configurações dinâmicas via variáveis de ambiente injetadas pelo Terraform no GCP
PROJECT_ID = os.getenv("GCP_PROJECT_ID", "ID-DO-SEU-PROJETO-GCP")
ENVIRONMENT = os.getenv("ENVIRONMENT", "dev")
BUCKET_NAME = os.getenv("GCS_BUCKET_BRONZE", f"{PROJECT_ID}-{ENVIRONMENT}-bronze")
BASE_URL = "https://dadosabertos.camara.leg.br/api/v2"

def get_gcs_client():
    """Inicializa o cliente do Google Cloud Storage com o respectivo ID do Projeto."""
    return storage.Client(project=PROJECT_ID)

def save_to_gcs(data, filename):
    """
    Salva uma lista de dicionários no GCS no formato NDJSON (Newline Delimited JSON).
    Esse formato é otimizado para que o BigQuery possa ler o arquivo como uma tabela externa.
    """
    client = get_gcs_client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(filename)
    
    # Conversão para NDJSON: uma linha por registro JSON
    ndjson_data = "\n".join([json.dumps(item, ensure_ascii=False) for item in data])
    
    blob.upload_from_string(
        data=ndjson_data,
        content_type='application/x-ndjson'
    )
    print(f"Arquivo {filename} salvo com sucesso no bucket {BUCKET_NAME} no formato NDJSON.")

@functions_framework.http
def ingest_deputados(request):
    """
    Cloud Function disparada via HTTP para coletar dados cadastrais de todos 
    os deputados ativos na legislatura atual.
    """
    url = f"{BASE_URL}/deputados"
    params = {"ordem": "ASC", "ordenarPor": "nome"}
    
    try:
        # Requisição à API oficial da Câmara
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json().get("dados", [])
        
        # Estrutura Hive Partitioning: bronze/deputados/year=YYYY/month=MM/day=DD/
        now = datetime.now()
        year = now.strftime("%Y")
        month = now.strftime("%m")
        day = now.strftime("%d")
        
        filename = f"bronze/deputados/year={year}/month={month}/deputados_{day}{month}{year}.json"
        
        # Persistência na camada Bronze (Raw Data)
        save_to_gcs(data, filename)
        
        return {"status": "success", "count": len(data), "file": filename}, 200
    except Exception as e:
        # Retorno de erro capturado para facilitar o debugging no Cloud Logs
        return {"status": "error", "message": str(e)}, 500

@functions_framework.http
def ingest_despesas(request):
    """
    Cloud Function que itera sobre os deputados e coleta suas despesas do ano corrente.
    Utiliza um parâmetro 'limit' (via query string) para evitar timeouts em execuções muito longas.
    """
    url_deputados = f"{BASE_URL}/deputados"
    ano_atual = datetime.now().year
    
    try:
        # 1. Busca a lista de todos os deputados para saber de quem coletar
        resp = requests.get(url_deputados)
        resp.raise_for_status()
        deputados = resp.json().get("dados", [])
        
        all_expenses = []
        
        # 2. Iteração sobre os deputados (limitado por segurança ou parametrização)
        limit = request.args.get("limit", 10) # Padrão de 10 deputados se não especificado
        
        for dep in deputados[:int(limit)]:
            dep_id = dep["id"]
            expense_url = f"{BASE_URL}/deputados/{dep_id}/despesas"
            
            # Coleta as despesas detalhadas do deputado no ano vigente
            exp_resp = requests.get(expense_url, params={"ano": ano_atual})
            if exp_resp.status_code == 200:
                expenses = exp_resp.json().get("dados", [])
                
                # Injeta o 'idDeputado' em cada linha de despesa para permitir o JOIN no DW
                for exp in expenses:
                    exp["idDeputado"] = dep_id
                    all_expenses.append(exp)
        
        # 3. Nomeação e persistência em estrutura Hive Partitioning
        now = datetime.now()
        year = now.strftime("%Y")
        month = now.strftime("%m")
        day = now.strftime("%d")

        filename = f"bronze/despesas/year={year}/month={month}/despesas_{day}{month}{year}.json"
        
        save_to_gcs(all_expenses, filename)
        
        return {
            "status": "success", 
            "deputados_processed": int(limit), 
            "total_expenses": len(all_expenses),
            "file": filename
        }, 200
        
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500
