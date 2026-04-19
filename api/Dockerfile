# 1. Imagem base: Python 3.10 em versão 'slim' para ser leve e rápido
FROM python:3.10-slim

# 2. Configurações de ambiente:
# PYTHONDONTWRITEBYTECODE: Evita que o Python gere arquivos .pyc
# PYTHONUNBUFFERED: Permite ver logs em tempo real sem atraso no console
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 3. Diretório de trabalho: onde a aplicação vai morar dentro do contêiner
WORKDIR /app

# 4. Instalação de dependências do sistema Linux (necessárias para compilação)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# 5. Camada de dependências Python:
# Copiamos primeiro apenas o requirements para aproveitar o cache do Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copia todo o código da pasta /api para dentro do contêiner
COPY . .

# 7. Documentação da porta: O Cloud Run usa a porta 8080 por padrão
EXPOSE 8080

# 8. Comando de inicialização: roda a API usando o servidor Uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
