# Project Configuration
project_id = "gke-111111"
region     = "us-central1"

# Project information
project_name = "gke-111111"
environment  = "dev"

# App Engine (if required for Firestore)
app_engine_location = "us-central1"

# Firestore Database Configuration
database_name                 = "firestore-dev"
database_location             = "us-central1"
database_type                 = "FIRESTORE_NATIVE"
concurrency_mode              = "OPTIMISTIC"
create_sample_indexes         = true

# Labels for resource management
labels = {
  project     = "gke-111111"
  environment = "dev"
}
