variable "project_id" {
  description = "The GCP Project ID"
  type        = str
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}
