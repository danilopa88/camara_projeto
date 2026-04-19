# Pipeline de Dados: Câmara dos Deputados

Projeto de Engenharia de Dados profissional utilizando a **Medallion Architecture** (Bronze, Silver, Gold), focado em escalabilidade, segurança e automação total no Google Cloud Platform (GCP).

## 📊 Arquitetura do Projeto

A solução é composta por cinco etapas principais:

1.  **Ingestão (Cloud Functions)**: Scripts Python que coletam dados e salvam em **NDJSON** no GCS.
2.  **Captura de Mudanças (dbt Snapshots)**: Implementação de **CDC (Change Data Capture)** para rastrear o histórico de alterações cadastrais e financeiras (SCD Type 2).
3.  **Staging (Bronze Layer)**: Limpeza inicial e padronização. Aqui geramos os metadados de auditoria:
    -   `processed_at`: Data da primeira aparição do registro.
    -   `modified_at`: Data da última alteração detectada.
4.  **Transformação (Silver Layer)**: Modelagem dimensional e fatos com nomes de colunas internacionalizados (**English**).
5.  **Exposição (Gold Layer)**: Views otimizadas para consumo direto no **Looker Studio**.

---

## 🛠️ Tecnologias Utilizadas

-   **Modelagem**: dbt Cloud (SQL) com nomes de colunas em **Inglês** para compatibilidade global.
-   **Documentação**: Catálogo de dados integrado via arquivos `schema.yml`.

---

## 🚀 Como Iniciar

### 1. Configuração Local (Ambiente de Desenvolvimento)

Para rodar os scripts localmente sem precisar de chaves JSON, utilize o **Application Default Credentials (ADC)**:

```powershell
# Autenticar localmente
gcloud auth application-default login
gcloud auth application-default set-quota-project SEU_PROJECT_ID

# Instalar dependências
pip install -r requirements.txt
```

### 2. Infraestrutura (Terraform)

O projeto utiliza um **Backend Remoto** no GCS para garantir que o estado da infraestrutura seja compartilhado entre o desenvolvedor e o GitHub Actions.

```powershell
cd terraform
terraform init
terraform apply -var="environment=dev"
```

### 3. Executando a Ingestão (Local)

Use o `functions-framework` para simular o comportamento da Cloud Function:

```powershell
functions-framework --target ingest_deputados --port 8080 --debug
curl http://localhost:8080
```

---

## 🔄 Esteira de CI/CD (GitHub Actions)

O projeto possui automação completa via GitHub Actions, utilizando **autenticação keyless (OIDC)**.

-   **Plan**: Executado em Pull Requests para validar mudanças na infraestrutura.
-   **Apply**: Executado automaticamente no Push para as branches `dev` (ambiente Dev) ou `main` (ambiente Main).

**Segurança**: Não utilizamos arquivos `chaves.json` no GitHub. A conexão é feita via Workload Identity Pool configurado no GCP.

---

## 📂 Estrutura de Pastas

```text
├── .github/workflows/  # Esteiras de CI/CD (OIDC)
├── api/                # Servidor FastAPI
├── dbt/                # Modelos SQL para dbt Cloud
├── ingestion/          # Lógica das Cloud Functions (Python)
├── terraform/          # IaC (GCS, BigQuery, Backend Remoto)
└── requirements.txt    # Dependências do projeto
```

---

## 📧 Contato
Projeto desenvolvido por [Danilo Paes](https://github.com/danilopa88).
