#############################################
# Project Configuration
#############################################

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "us-central1"
}

#############################################
# App Engine Configuration
#############################################

variable "app_engine_location" {
  description = "The location for the App Engine application"
  type        = string
  default     = "us-central"
  validation {
    condition = contains([
      "us-central", "us-east1", "us-east4", "us-west1", "us-west2",
      "europe-west1","europe-west2","europe-west3","europe-west4",
      "asia-south1","asia-south2","asia-east1","asia-east2",
      "asia-northeast1","asia-northeast2","asia-northeast3",
      "australia-southeast1","australia-southeast2"
    ], var.app_engine_location)
    error_message = "app engine location must be a valid App Engine region."
  }
}

variable "create_app_engine" {
  description = "Whether to create App Engine application (set to false if it already exists)"
  type        = bool
  default     = false
}

#############################################
# Firestore Database Configuration
#############################################

variable "database_name" {
  description = "Name of the Firestore database"
  type        = string
  default     = ""
}

variable "database_location" {
  description = "Location for the Firestore database"
  type        = string
  default     = "us-central1"
  validation {
    condition = contains([
      "us-central", "us-central1", "us-east1", "us-east4", "us-west1",
      "europe-west1","europe-west4","europe-west3","europe-west2",
      "asia-east1","asia-east2","asia-south1","asia-south2",
      "asia-northeast1","asia-northeast2","asia-northeast3"
    ], var.database_location)
    error_message = "database location must be a valid Firestore region."
  }
}

variable "database_type" {
  description = "The type of Firestore database"
  type        = string
  default     = "FIRESTORE_NATIVE"
  validation {
    condition = contains(["FIRESTORE_NATIVE", "DATASTORE_MODE"], var.database_type)
    error_message = "database type must be either FIRESTORE_NATIVE or DATASTORE_MODE."
  }
}

variable "concurrency_mode" {
  description = "Concurrency mode for the Firestore database"
  type        = string
  default     = "OPTIMISTIC"
  validation {
    condition = contains(["OPTIMISTIC", "PESSIMISTIC"], var.concurrency_mode)
    error_message = "concurrency mode must be OPTIMISTIC or PESSIMISTIC."
  }
}

#############################################
# *** FIX #1 — ADD THIS MISSING VARIABLE ***
#############################################

variable "app_engine_integration_mode" {
  description = "App Engine integration mode for Firestore"
  type        = string
  default     = "DISABLED"
  validation {
    condition = contains(["DISABLED", "ENABLED"], var.app_engine_integration_mode)
    error_message = "app_engine_integration_mode must be either DISABLED or ENABLED."
  }
}

#############################################
# *** FIX #2 — RENAME THIS VARIABLE ***
#############################################

variable "point_in_time_recovery_enablement" {
  description = "Point in time recovery enablement"
  type        = string
  default     = "POINT_IN_TIME_RECOVERY_DISABLED"
  validation {
    condition = contains(["POINT_IN_TIME_RECOVERY_ENABLED", "POINT_IN_TIME_RECOVERY_DISABLED"], var.point_in_time_recovery_enablement)
    error_message = "Point-in-time recovery enablement must be valid."
  }
}

#############################################
# Firestore delete protection
#############################################

variable "delete_protection_state" {
  description = "The delete protection state for the database"
  type        = string
  default     = "DELETE_PROTECTION_ENABLED"
  validation {
    condition = contains(["DELETE_PROTECTION_ENABLED", "DELETE_PROTECTION_DISABLED"], var.delete_protection_state)
    error_message = "delete protection state must be either DELETE_PROTECTION_ENABLED or DELETE_PROTECTION_DISABLED."
  }
}

#############################################
# Firestore Indexes
#############################################

variable "create_sample_indexes" {
  description = "Whether to create sample Firestore indexes"
  type        = bool
  default     = true
}

#############################################
# Database Creation Control
#############################################

variable "create_firestore_database" {
  description = "Whether to create Firestore database (set to false if it already exists)"
  type        = bool
  default     = false
}

#############################################
# Environment and Tagging
#############################################

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "non-prod"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "rate-automation"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default = {
    project     = "rate-automation"
    environment = "non-prod"
    managed_by  = "terraform"
    service     = "firestore"
  }
}
