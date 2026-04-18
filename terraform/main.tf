terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# --- Google Cloud Storage ---

resource "google_storage_bucket" "bronze_bucket" {
  name          = "${var.project_id}-${var.environment}-bronze"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
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
