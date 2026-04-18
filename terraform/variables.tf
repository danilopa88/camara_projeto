variable "project_id" {
  description = "The GCP Project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

variable "environment" {
  description = "The deployment environment (dev, release, main)"
  type        = string
  default     = "dev"
}

variable "ingestion_cron" {
  description = "Cron schedule for the ingestion function (default: daily at 03:00 AM)"
  type        = string
  default     = "0 3 * * *"
}
