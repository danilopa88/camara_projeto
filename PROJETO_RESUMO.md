# Jornada de Engenharia de Dados: Da API ao Analytics Automatizado 🚀

Este documento resume todos os passos técnicos, decisões e superações que tivemos para construir o seu Data Warehouse profissional utilizando a arquitetura Medallion no Google Cloud.

---

## 🏗️ 1. O Conceito: Arquitetura Medallion
Nosso objetivo foi criar um fluxo onde o dado flui de forma organizada:
- **Bronze (Bruto)**: Os arquivos originais da API salvos no Cloud Storage.
- **Silver (Limpeza)**: Views no BigQuery que limpam, tipam e deduplicam os dados.
- **Gold (Negócio)**: Tabelas finais prontas para Dashboards (ex: gastos por partido).

---

## 🛠️ 2. Primeira Etapa: Ingestão e Formatação
Começamos com scripts Python para buscar dados da API da Câmara.

> [!IMPORTANT]
> **A Sacada Técnica**: Mudamos o formato de salvamento de JSON simples para **NDJSON (Newline Delimited JSON)**. 
> Por que? O BigQuery exige esse formato para conseguir ler arquivos como se fossem tabelas de forma automática.

- **Ferramentas**: Python, Requests e Google Cloud Storage SDK.

---

## ☁️ 3. Segunda Etapa: Infraestrutura como Código (Terraform)
Usamos o **Terraform** para provisionar toda a nuvem de forma automática:
- **Buckets**: Caixas separadas para código e para os dados.
- **BigQuery Link**: Tabelas externas que refletem os arquivos do Storage em tempo real.

---

## 📊 4. Quarta Etapa: O "Cérebro" dbt (Analytics)
O dbt (Data Build Tool) foi usado para transformar o dado bruto em inteligência:
- **Deduplicação**: Lógica de `ROW_NUMBER()` para pegar sempre o estado mais atual dos dados.
- **Camadas**: Separação física e lógica entre limpeza (Silver) e agregação (Gold).

---

## 🤖 5. Quinta Etapa: Automação e Segurança (CI/CD)
O ponto alto do projeto foi a automação via **GitHub Actions**:
- **Chave Zero (OIDC)**: Autenticação via Workload Identity Federation (sem arquivos JSON de chave).
- **Master Pipeline**: Unificação de Infra e Dados em uma única esteira sequencial.

---

## 🐳 6. Sexta Etapa: Docker (A "Mala" da sua API)
Para que a sua API rodasse no Google Cloud sem erros de "funciona na minha máquina", usamos o **Docker**. 

- **O que ele faz?** Ele empacota o seu código junto com todas as ferramentas necessárias (Python, bibliotecas, configurações) dentro de um **Contêiner**. 
- **Benefício**: Esse contêiner é como um arquivo blindado. O Google Cloud simplesmente o executa, garantindo que ele rode exatamente da mesma forma que rodaria no seu computador.
- **Dockerfile**: É a "receita de bolo" que usamos para criar esse contêiner.

---

## 🔐 Apêndice: Comandos de Terminal (Manual)

Aqui estão os comandos críticos executados via terminal para "destravar" o projeto:

### 1. Desbloqueio de Infra (O "Master Key")
Dada a restrição de IAM, promovemos a conta do GitHub a **Owner** temporariamente para permitir o deploy completo:

```powershell
$PROJ="Nome_do_Projeto"
$SA_EMAIL="github-actions-sa@Nome_do_Projeto.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJ --member="serviceAccount:$SA_EMAIL" --role="roles/owner"
```

### 2. Autenticação Local (ADC)
Para rodar a ingestão no computador local conectando ao bucket oficial:

```powershell
gcloud auth application-default login
```

### 3. Ativação de APIs Críticas (Habilitação de Recursos)
Este comando é o "disjuntor" que liga as permissões de infraestrutura. Sem habilitar essas APIs, o Google Cloud bloqueia qualquer tentativa do Terraform de criar ou até mesmo listar recursos. 

O que cada "peça" faz aqui:
- **serviceusage.googleapis.com**: A "chave mestra". Permite habilitar todas as outras APIs via código.
- **cloudresourcemanager.googleapis.com**: Permite ao sistema gerenciar a hierarquia do projeto e aplicar permissões (IAM) em nível de projeto.
- **iam.googleapis.com**: O motor de Identidade. Permite criar Contas de Serviço (como as que o GitHub e a API usam).
- **serverless.googleapis.com**: Habilita o ambiente para Cloud Functions e Cloud Run.

```powershell
# Este comando deve ser executado uma única vez pelo dono do projeto
gcloud services enable `
    serviceusage.googleapis.com `
    cloudresourcemanager.googleapis.com `
    iam.googleapis.com `
    serverless.googleapis.com `
    --project $PROJ
```

### 4. Configuração do WIF (O "Aperto de Mão" Seguro)
Este comando é o coração da nossa segurança **Keyless (Sem Chave)**. Ele cria um vínculo de confiança entre o repositório do GitHub e a Conta de Serviço do Google Cloud. 

Em vez de salvar senhas (chaves JSON), o GitHub gera um token temporário que o Google valida usando esta regra:

- **roles/iam.workloadIdentityUser**: Permite que uma identidade externa (GitHub) "assuma a identidade" de uma conta do Google.
- **principalSet**: Define o filtro de segurança máximo. Ele especifica que **somente** o seu repositório (`Nome_do_Usuario/Nome_do_Projeto`) vindo do Pool de Identidade do GitHub tem permissão para entrar.

```powershell
# Este comando "casa" o seu repositório GitHub com a conta de serviço do Google
gcloud iam service-accounts add-iam-policy-binding $SA_EMAIL `
    --project=$PROJ `
    --role="roles/iam.workloadIdentityUser" `
    --member="principalSet://iam.googleapis.com/projects/310127108141/locations/global/workloadIdentityPools/github-pool/attribute.repository/Nome_do_Usuario/Nome_do_Projeto"
```

---

### 🔜 Próximos Passos Sugeridos:
1. **Deploy da API**: Subir o FastAPI para o Cloud Run.
2. **Dashboard**: Conectar ferramentas de BI (Looker/PowerBI) na base Gold.
