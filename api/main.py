from fastapi import FastAPI, HTTPException
from google.cloud import bigquery
import os
from typing import List, Optional
from pydantic import BaseModel
from dotenv import load_dotenv

# Carrega variáveis do arquivo .env
load_dotenv()

app = FastAPI(title="API Dados Câmara - Analytics")

# Configurações
PROJECT_ID = os.getenv("GCP_PROJECT_ID", "ID-DO-SEU-PROJETO-GCP")
DATASET_GOLD = "gold"  # Nome do dataset onde o dbt salva a camada Gold

client = bigquery.Client(project=PROJECT_ID)

class RankingPartido(BaseModel):
    partido_sigla: str
    estado_sigla: str
    total_gasto: float
    total_deputados: int
    gasto_medio_por_deputado: float

@app.get("/")
def read_root():
    return {"message": "Bem-vindo à API de Analytics da Câmara dos Deputados"}

@app.get("/gastos/ranking-partidos", response_model=List[RankingPartido])
def get_ranking_partidos(limit: int = 10):
    """Retorna os partidos que mais gastaram no ano corrente."""
    query = f"""
        SELECT 
            partido_sigla, 
            estado_sigla, 
            total_gasto, 
            total_deputados, 
            gasto_medio_por_deputado
        FROM `{PROJECT_ID}.{DATASET_GOLD}.agg_despesas_partido`
        ORDER BY total_gasto DESC
        LIMIT @limit
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("limit", "INT64", limit)
        ]
    )
    
    try:
        query_job = client.query(query, job_config=job_config)
        results = query_job.result()
        
        return [dict(row) for row in results]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/deputados/gastos/{partido}")
def get_gastos_por_partido(partido: str):
    """Busca o total gasto por um partido específico."""
    query = f"""
        SELECT 
            SUM(total_gasto) as gasto_total_partido
        FROM `{PROJECT_ID}.{DATASET_GOLD}.agg_despesas_partido`
        WHERE partido_sigla = @partido
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("partido", "STRING", partido.upper())
        ]
    )
    
    try:
        query_job = client.query(query, job_config=job_config)
        result = list(query_job.result())
        if not result or result[0].gasto_total_partido is None:
            return {"partido": partido, "gasto_total": 0}
        return {"partido": partido, "gasto_total": result[0].gasto_total_partido}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
