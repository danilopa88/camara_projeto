import os
os.environ['ENVIRONMENT'] = 'dev'
os.environ['GCP_PROJECT_ID'] = 'project-c5dccf2b-d62c-4831-b0d'

import sys
sys.path.append('.')

from main import ingest_deputados, ingest_despesas

class DummyRequest:
    args = {'limit': 10}

print('Ingesting deputados...')
res1 = ingest_deputados(DummyRequest())
print(res1)

print('Ingesting despesas...')
res2 = ingest_despesas(DummyRequest())
print(res2)
