terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- APIs ---

resource "google_project_service" "services" {
  for_each = toset([
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "run.googleapis.com",
    "cloudscheduler.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "storage.googleapis.com"
  ])
  service            = each.key
  disable_on_destroy = false
}

# --- Google Cloud Storage ---

resource "google_storage_bucket" "functions_source" {
  name          = "${var.project_id}-${var.environment}-functions-source"
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

resource "google_storage_bucket" "bronze_bucket" {
  name          = "${var.project_id}-${var.environment}-bronze"
  location      = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# --- Cloud Functions (v2) ---

resource "google_service_account" "ingestion_sa" {
  account_id   = "ingestion-sa"
  display_name = "Ingestion Service Account for Cloud Functions"
}

resource "google_storage_bucket_iam_member" "bronze_writer" {
  bucket = google_storage_bucket.bronze_bucket.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.ingestion_sa.email}"
}

# Permissões extras para que a conta possa realizar o Build (v2)
resource "google_project_iam_member" "ingestion_build_roles" {
  for_each = toset([
    "roles/logging.logWriter",
    "roles/artifactregistry.writer",
    "roles/storage.objectViewer"
  ])
  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.ingestion_sa.email}"
}

# Permissão para o GitHub Actions SA "agir como" a ingestion-sa (Nível de Recurso)
resource "google_service_account_iam_member" "github_actions_act_as_ingestion" {
  service_account_id = google_service_account.ingestion_sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Permissão para o GitHub Actions SA "agir como" qualquer SA (Nível de Projeto - Mais forte)
resource "google_project_iam_member" "github_actions_sa_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Permissão para o GitHub Actions SA gerenciar permissões (Auto-gestão de IAM)
resource "google_project_iam_member" "github_actions_iam_admin" {
  project = var.project_id
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

# Permissão específica para agir como a conta padrão de computação (necessário para o Cloud Build)
resource "google_project_iam_member" "github_actions_act_as_compute" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:github-actions-sa@${var.project_id}.iam.gserviceaccount.com"
}

data "archive_file" "ingestion_zip" {
  type        = "zip"
  source_dir  = "../ingestion"
  output_path = "ingestion.zip"
  excludes    = ["__pycache__"]
}

resource "google_storage_bucket_object" "ingestion_code" {
  name   = "ingestion-${data.archive_file.ingestion_zip.output_md5}.zip"
  bucket = google_storage_bucket.functions_source.name
  source = data.archive_file.ingestion_zip.output_path
}

resource "google_cloudfunctions2_function" "ingest_deputados" {
  name        = "ingest-deputados"
  location    = var.region
  description = "Coleta dados de deputados da API da Câmara"

  build_config {
    runtime     = "python310"
    entry_point = "ingest_deputados"
    service_account = google_service_account.ingestion_sa.id # USA A NOSSA CONTA NO BUILD
    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.ingestion_code.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "256Mi"
    timeout_seconds    = 60
    service_account_email = google_service_account.ingestion_sa.email
    ingress_settings      = "ALLOW_ALL" # Público conforme solicitado
  }

  depends_on = [
    google_project_service.services,
    google_service_account_iam_member.github_actions_act_as_ingestion,
    google_project_iam_member.github_actions_sa_user
  ]
}

resource "google_cloudfunctions2_function" "ingest_despesas" {
  name        = "ingest-despesas"
  location    = var.region
  description = "Coleta despesas dos deputados da API da Câmara"

  build_config {
    runtime     = "python310"
    entry_point = "ingest_despesas"
    service_account = google_service_account.ingestion_sa.id # USA A NOSSA CONTA NO BUILD
    source {
      storage_source {
        bucket = google_storage_bucket.functions_source.name
        object = google_storage_bucket_object.ingestion_code.name
      }
    }
  }

  service_config {
    max_instance_count = 1
    available_memory   = "512Mi" # Despesas precisam de mais RAM
    timeout_seconds    = 540     # Timeout longo para processar deputados
    service_account_email = google_service_account.ingestion_sa.email
    ingress_settings      = "ALLOW_ALL"
  }

  depends_on = [
    google_project_service.services,
    google_service_account_iam_member.github_actions_act_as_ingestion,
    google_project_iam_member.github_actions_sa_user
  ]
}

# --- Cloud Scheduler ---

resource "google_cloud_scheduler_job" "daily_ingest_deputados" {
  name        = "daily-ingest-deputados"
  description = "Dispara a ingestão de deputados diariamente"
  schedule    = var.ingestion_cron
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.ingest_deputados.service_config[0].uri
  }
}

resource "google_cloud_scheduler_job" "daily_ingest_despesas" {
  name        = "daily-ingest-despesas"
  description = "Dispara a ingestão de despesas diariamente"
  schedule    = var.ingestion_cron
  region      = var.region

  http_target {
    http_method = "POST"
    uri         = google_cloudfunctions2_function.ingest_despesas.service_config[0].uri
  }
}

# --- Public Access (requested) ---

resource "google_cloud_run_service_iam_member" "deputados_public" {
  location = google_cloudfunctions2_function.ingest_deputados.location
  service  = google_cloudfunctions2_function.ingest_deputados.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "despesas_public" {
  location = google_cloudfunctions2_function.ingest_despesas.location
  service  = google_cloudfunctions2_function.ingest_despesas.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# --- BigQuery Datasets ---

resource "google_bigquery_dataset" "bronze" {
  dataset_id                  = "${var.environment}_bronze"
  friendly_name               = "Bronze Layer (${var.environment})"
  description                 = "Dados brutos carregados via Cloud Functions"
  location                    = var.region
}

resource "google_bigquery_dataset" "silver" {
  dataset_id                  = "${var.environment}_silver"
  friendly_name               = "Silver Layer (${var.environment})"
  description                 = "Dados limpos e tipados via dbt"
  location                    = var.region
}

resource "google_bigquery_dataset" "gold" {
  dataset_id                  = "${var.environment}_gold"
  friendly_name               = "Gold Layer (${var.environment})"
  description                 = "Dados agregados e analytics via dbt"
  location                    = var.region
}

# --- External Tables (Bronze Link) ---

resource "google_bigquery_table" "raw_deputados" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_deputados"

  external_data_configuration {
    autodetect    = true
    source_format = "NEWLINE_DELIMITED_JSON"
    source_uris   = ["gs://${google_storage_bucket.bronze_bucket.name}/bronze/deputados/*.json"]
  }
}

resource "google_bigquery_table" "raw_despesas" {
  dataset_id = google_bigquery_dataset.bronze.dataset_id
  table_id   = "raw_despesas"

  external_data_configuration {
    autodetect    = true
    source_format = "NEWLINE_DELIMITED_JSON"
    source_uris   = ["gs://${google_storage_bucket.bronze_bucket.name}/bronze/despesas/*.json"]
  }
}
