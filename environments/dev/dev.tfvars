# Project Configuration
project_id = "myproject-non-prod"
region     = "us-central1"

# Project information
project_name = "myproject-non-prod"
environment  = "dev"

# App Engine (if required for Firestore)
app_engine_location = "us-central"

# Firestore Database Configuration
database_name                 = "firestore-dev"
database_location             = "us-central1"
database_type                 = "FIRESTORE_NATIVE"
concurrency_mode              = "OPTIMISTIC"
app_engine_integration_mode     = "DISABLED"
point_in_time_recovery_enablement = "POINT_IN_TIME_RECOVERY_ENABLED"
delete_protection_state         = "DELETE_PROTECTION_ENABLED"

# Firestore features
create_sample_indexes = true

# Labels for resource management
labels = {
  project     = "myproject-non-prod"
  environment = "dev"
}
