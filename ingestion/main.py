import requests
import json
import os
from datetime import datetime
from google.cloud import storage
import functions_framework
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env se existir
load_dotenv()

# Configurações via variáveis de ambiente
PROJECT_ID = os.getenv("GCP_PROJECT_ID", "ID-DO-SEU-PROJETO-GCP")
BUCKET_NAME = os.getenv("GCS_BUCKET_BRONZE", "NOME-DO-SEU-BUCKET")
BASE_URL = "https://dadosabertos.camara.leg.br/api/v2"

def get_gcs_client():
    return storage.Client(project=PROJECT_ID)

def save_to_gcs(data, filename):
    client = get_gcs_client()
    bucket = client.bucket(BUCKET_NAME)
    blob = bucket.blob(filename)
    blob.upload_from_string(
        data=json.dumps(data, indent=2, ensure_ascii=False),
        content_type='application/json'
    )
    print(f"Arquivo {filename} salvo com sucesso no bucket {BUCKET_NAME}.")

@functions_framework.http
def ingest_deputados(request):
    """Fetch all active deputies and save to Bronze GCS."""
    url = f"{BASE_URL}/deputados"
    params = {"ordem": "ASC", "ordenarPor": "nome"}
    
    try:
        response = requests.get(url, params=params)
        response.raise_for_status()
        data = response.json().get("dados", [])
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"bronze/deputados/deputados_{timestamp}.json"
        
        save_to_gcs(data, filename)
        
        return {"status": "success", "count": len(data), "file": filename}, 200
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500

@functions_framework.http
def ingest_despesas(request):
    """
    Fetch expenses for all deputies for the current year.
    Note: In a production environment with 513 deputies, this might 
    hit Cloud Function timeouts. It's recommended to trigger this per deputy
    or use a background task / orchestration.
    """
    url_deputados = f"{BASE_URL}/deputados"
    ano_atual = datetime.now().year
    
    try:
        # 1. Get List of Deputies
        resp = requests.get(url_deputados)
        resp.raise_for_status()
        deputados = resp.json().get("dados", [])
        
        all_expenses = []
        
        # 2. Iterate (Limited to first 5 for testing/demonstration)
        # In real scenario, use a queue or parallel triggers
        limit = request.args.get("limit", 10) # Process 10 by default for safety
        
        for dep in deputados[:int(limit)]:
            dep_id = dep["id"]
            expense_url = f"{BASE_URL}/deputados/{dep_id}/despesas"
            exp_resp = requests.get(expense_url, params={"ano": ano_atual})
            if exp_resp.status_code == 200:
                expenses = exp_resp.json().get("dados", [])
                # Add dep metadata to each expense line
                for exp in expenses:
                    exp["idDeputado"] = dep_id
                    all_expenses.append(exp)
        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"bronze/despesas/despesas_{timestamp}.json"
        
        save_to_gcs(all_expenses, filename)
        
        return {
            "status": "success", 
            "deputados_processed": int(limit), 
            "total_expenses": len(all_expenses),
            "file": filename
        }, 200
        
    except Exception as e:
        return {"status": "error", "message": str(e)}, 500
