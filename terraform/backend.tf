terraform {
  backend "gcs" {
    bucket = "project-c5dccf2b-d62c-4831-b0d-tfstate"
    prefix = "terraform/state"
  }
}
