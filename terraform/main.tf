# Parte 3 — Infraestructura como código (Terraform)
# Declara el estado deseado: un repositorio de Artifact Registry y el servicio
# de Cloud Run del monolito. Terraform calcula el plan y lo aplica.

terraform {
  required_version = ">= 1.5"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
variable "project_id" {
  type    = string
  default = "lab6-501800"
}

variable "region" {
  type    = string
  default = "southamerica-west1"
}

# Imagen ya publicada por la pipeline de la Parte 2. Terraform NO construye
# imágenes: solo declara la infraestructura y referencia una imagen existente.
variable "image" {
  type    = string
  default = "southamerica-west1-docker.pkg.dev/lab6-501800/monolito/incidentes:v1"
}

# ---------------------------------------------------------------------------
# Provider
# ---------------------------------------------------------------------------
provider "google" {
  project = var.project_id
  region  = var.region
}

# ---------------------------------------------------------------------------
# 1. Repositorio de imágenes en Artifact Registry
# ---------------------------------------------------------------------------
resource "google_artifact_registry_repository" "monolito" {
  repository_id = "monolito-tf"
  location      = var.region
  format        = "DOCKER"
  description   = "Repositorio de imágenes del monolito, gestionado por Terraform"
}

# ---------------------------------------------------------------------------
# 2. Servicio de Cloud Run del monolito
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service" "incidentes" {
  name                = "incidentes-tf"
  location            = var.region
  deletion_protection = false # permite que `terraform destroy` lo elimine

  template {
    containers {
      image = var.image
    }
  }
}

# ---------------------------------------------------------------------------
# 3. Acceso público (equivalente a --allow-unauthenticated)
# ---------------------------------------------------------------------------
resource "google_cloud_run_v2_service_iam_member" "public" {
  name     = google_cloud_run_v2_service.incidentes.name
  location = var.region
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# ---------------------------------------------------------------------------
# Salida: URL del servicio desplegado por Terraform
# ---------------------------------------------------------------------------
output "service_url" {
  value = google_cloud_run_v2_service.incidentes.uri
}
