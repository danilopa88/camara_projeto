# Pipeline de Dados: Câmara dos Deputados

Projeto de Engenharia de Dados com arquitetura Medallion (GCP).

## Infraestrutura (IaC)
Usamos **Terraform** para provisionar os recursos no GCP.

1.  Acesse a pasta `terraform/`.
2.  Rode os comandos:
    ```bash
    terraform init
    terraform apply
    ```
Isso criará automaticamente o bucket Bronze e os datasets `bronze`, `silver` e `gold` no BigQuery.

## Arquitetura
1.  **Ingestão (Cloud Functions)**: Scripts Python que coletam dados da API da Câmara e salvam no Google Cloud Storage (Bronze).
2.  **Modelagem (dbt Cloud)**: Transformações SQL que processam os dados do Bronze para Silver e Gold no BigQuery.
3.  **Entrega (API REST)**: Interface FastAPI para consulta em tempo real dos insights da camada Gold.

## Estrutura do Projeto
- `/ingestion`: Código para deploying no Google Cloud Functions.
- `/dbt`: Modelos SQL e arquivos de configuração para o dbt Cloud.
- `/api`: Servidor FastAPI para entrega dos dados.

## Como Executar Localmente

### 1. Ingestão
Configure as variáveis de ambiente:
```bash
export GCP_PROJECT_ID="project-c5dccf2b-d62c-4831-b0d"
export GCS_BUCKET_BRONZE="seu-bucket-bronze"
```
Instale as dependências e rode a função:
```bash
pip install -r requirements.txt
functions-framework --target ingest_deputados --port 8080
```

### 2. API Analytics
Para rodar a API de consulta ao BigQuery:
```bash
python api/main.py
```
Acesse `http://localhost:8000/docs` para a documentação interativa.

## dbt Cloud
Copie os arquivos da pasta `/dbt` para o seu repositório Git conectado ao dbt Cloud. Certifique-se de configurar a `Service Account` no dbt Cloud com acesso ao seu projeto BigQuery.
