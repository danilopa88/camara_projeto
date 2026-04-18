# Plataforma de Dados Medallion: Câmara dos Deputados 🚀

Este documento é o guia técnico completo da solução de Data Warehouse construída para a análise de despesas da Câmara dos Deputados. Aqui detalhamos a arquitetura, os arquivos fonte e as decisões de engenharia.

---

## 🏗️ 1. Arquitetura e Fluxo de Dados
A solução utiliza a **Arquitetura Medallion** no Google Cloud Platform, garantindo rastreabilidade e qualidade dos dados desde a origem até a entrega.

![Diagrama de Arquitetura](docs/arquitetura_medallion.png)

---

## 🛠️ 2. Ingestão Serverless (Camada Bronze)
Os dados são extraídos da API oficial da Câmara e armazenados em formato bruto no Cloud Storage.

- **Arquivo Principal**: [`ingestion/main.py`](ingestion/main.py)
- **Lógica**: Scripts Python modulares que iteram sobre os deputados e buscam suas despesas mensais, convertendo-as para **NDJSON** (exigência do BigQuery).
- **Dependências**: [`ingestion/requirements.txt`](ingestion/requirements.txt)
- **Agendamento**: Orquestrado pelo **Cloud Scheduler**, disparando as Cloud Functions diariamente às 03:00 AM.

---

## ☁️ 3. Infraestrutura como Código (Terraform)
Toda a infraestrutura do GCP é provisionada e gerenciada via código, permitindo reprodutibilidade total.

- **Recursos Principais**: [`terraform/main.tf`](terraform/main.tf) (Buckets, Cloud Functions, Cloud Run, BigQuery Datasets).
- **Variáveis**: [`terraform/variables.tf`](terraform/variables.tf) (IDs de projeto, regiões e nomes de ambiente).
- **Estado**: [`terraform/backend.tf`](terraform/backend.tf) (Configuração do GCS para armazenar o estado do Terraform).

---

## 📊 4. Analytics e Transformação (dbt)
O **dbt (Data Build Tool)** atua como o motor de elite para transformar o dado bruto em inteligência de negócio.

### 🥉 Camada Bronze (Staging)
- **Modelos**: [`dbt/models/bronze/stg_despesas.sql`](dbt/models/bronze/stg_despesas.sql) e [`stg_deputados.sql`](dbt/models/bronze/stg_deputados.sql).
- **Foco**: Renomeação de colunas, tipagem (Casting) e extração de campos complexos.
- **Fontes**: [`dbt/models/bronze/sources.yml`](dbt/models/bronze/sources.yml).

### 🥈 Camada Silver (Truth Layer)
- **Modelo**: [`dbt/models/silver/fct_despesas.sql`](dbt/models/silver/fct_despesas.sql).
- **Foco**: Limpeza técnica e **Deduplicação**. Removemos redundâncias para garantir que cada despesa seja única no DW.

### 🥇 Camada Gold (Business Layer)
- **Modelo**: [`dbt/models/gold/agg_despesas_partido.sql`](dbt/models/gold/agg_despesas_partido.sql).
- **Foco**: Agregações de alto nível para Dashboards (ex: ranking de gastos por partido/estado).

### 🛠️ Configuração de Roteamento
- **Macro Customizada**: [`dbt/macros/generate_schema_name.sql`](dbt/macros/generate_schema_name.sql).
- **Objetivo**: Garante que cada camada caia no dataset correto do BigQuery (`dev_bronze`, `dev_silver`, `dev_gold`).
- **Arquivos de Projeto**: [`dbt_project.yml`](dbt/dbt_project.yml) e [`profiles.yml`](dbt/profiles.yml).

---

## 🤖 5. Automação CI/CD (GitHub Actions)
A esteira de integração e entrega contínua garante que qualquer mudança no código seja testada e deployada automaticamente.

- **Workflow**: [`.github/workflows/data-pipeline.yml`](.github/workflows/data-pipeline.yml)
- **Segurança**: Autenticação via **Workload Identity Federation** (Sem chaves JSON estáticas).
- **Sequência**: Terraform (Infra) -> Docker Build (API) -> Cloud Run Deploy -> dbt Build (Analytics).

---

## 🚀 6. Entrega via API (Cloud Run)
Os dados da camada Gold são expostos via uma API REST moderna para consumo de aplicações externas.

- **Código da API**: [`api/main.py`](api/main.py) (FastAPI).
- **Containerização**: [`api/Dockerfile`](api/Dockerfile).
- **Deploy**: Cloud Run (Serverless), escalando automaticamente de acordo com o tráfego.

---

## 🔐 Apêndice: Comandos Críticos de Manutenção
- **Rodar dbt localmente**: `dbt build --target dev`.
- **Habilitar APIs via Terminal**: `gcloud services enable ...` (ver detalhes no histórico de conversas).
- **Bootstrap da API**: No primeiro deploy, o Cloud Run usa a imagem `hello` para evitar erros de repositório vazio.

---
**Desenvolvido com foco em escalabilidade, segurança e excelência técnica.** 📉✨
