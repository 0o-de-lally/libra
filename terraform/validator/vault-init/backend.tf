terraform {
  backend "s3" {}  # AWS
  #backend "gcs" {}  # GCP
  #backend "azurerm" {}  # Azure

  #backend "s3" {   #SCW
    #skip_credentials_validation = true
    #skip_region_validation = true
  #}
}
