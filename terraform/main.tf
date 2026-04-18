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
  name          = "${var.project_id}-bronze"
  location      = var.region
  force_destroy = true

  uniform_bucket_level_access = true
}

# --- BigQuery Datasets ---

resource "google_bigquery_dataset" "bronze" {
  dataset_id                  = "bronze"
  friendly_name               = "Bronze Layer"
  description                 = "Dados brutos carregados via Cloud Functions"
  location                    = var.region
}

resource "google_bigquery_dataset" "silver" {
  dataset_id                  = "silver"
  friendly_name               = "Silver Layer"
  description                 = "Dados limpos e tipados via dbt"
  location                    = var.region
}

resource "google_bigquery_dataset" "gold" {
  dataset_id                  = "gold"
  friendly_name               = "Gold Layer"
  description                 = "Dados agregados e analytics via dbt"
  location                    = var.region
}
