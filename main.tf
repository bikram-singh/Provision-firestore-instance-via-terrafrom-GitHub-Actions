/*  Note: APIs should be enabled manually or via gcloud before running this Terraform
    gcloud services enable firestore.googleapis.com --project=myproject-non-prod
    gcloud services enable appengine.googleapis.com --project=myproject-non-prod
*/

# Note: App Engine application should be created manually if it doesn’t exist
# You can create it using: gcloud app create --region=us-central1 --project=myproject-non-prod

# Create App Engine application (only if create_app_engine is true)
resource "google_app_engine_application" "app" {
  count       = var.create_app_engine ? 1 : 0
  project     = var.project_id
  location_id = var.app_engine_location
  database_type = "CLOUD_FIRESTORE"
}

# Create Firestore database (only if create_firestore_database is true)
resource "google_firestore_database" "database" {
  count       = var.create_firestore_database ? 1 : 0
  project     = var.project_id
  name        = var.database_name
  location_id = var.database_location
  type        = var.database_type
  concurrency_mode             = var.concurrency_mode
  app_engine_integration_mode  = var.app_engine_integration_mode
  point_in_time_recovery_enablement = var.point_in_time_recovery_enablement
  delete_protection_state      = var.delete_protection_state
}

# Note: App Engine is required for Firestore, but we ensure it exists or is created via gcloud
# Remove explicit dependency since we handle App Engine creation in the workflow

# Create Firestore indexes (example)
resource "google_firestore_index" "user_status_index" {
  count      = var.create_sample_indexes ? 1 : 0
  project    = var.project_id
  database   = var.create_firestore_database ? google_firestore_database.database[0].name : var.database_name
  collection = "users"

  fields {
    field_path = "status"
    order      = "ASCENDING"
  }

  fields {
    field_path = "created_at"
    order      = "DESCENDING"
  }
}

resource "google_firestore_index" "order_timestamp_index" {
  count      = var.create_sample_indexes ? 1 : 0
  project    = var.project_id
  database   = var.create_firestore_database ? google_firestore_database.database[0].name : var.database_name
  collection = "orders"

  fields {
    field_path = "user_id"
    order      = "ASCENDING"
  }

  fields {
    field_path = "timestamp"
    order      = "DESCENDING"
  }
}

# Note: Dependencies handled by resource ordering — database must exist before indexes

# Note: Firestore security rules are not directly supported by Terraform
# They must be deployed manually using:
#   Firebase console: https://console.firebase.google.com/
#   Firebase CLI: firebase deploy --only firestore:rules
#   Google Cloud Console: https://console.cloud.google.com/firestore/rules

# For automated deployment, consider using the Firebase CLI in your CI/CD pipeline
# Example rules file (firestore.rules):
# rules_version = '2';
# service cloud.firestore {
#   match /databases/{database}/documents {
#     match /{document=**} {
#       allow read, write: if request.auth != null;
#     }
#   }
# }
