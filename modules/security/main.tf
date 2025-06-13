resource "google_project" "security_project" {
  name       = "Security Project"
  project_id = var.project_id
  org_id     = var.org_id
  billing_account = var.billing_account

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_service_account" "security_service_account" {
  account_id   = "security-sa"
  display_name = "Security Service Account"
  project      = google_project.security_project.project_id
}

resource "google_project_iam_member" "security_service_account_role" {
  project = google_project.security_project.project_id
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.security_service_account.email}"
}