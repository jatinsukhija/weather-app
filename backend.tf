terraform {
  backend "azurerm" {
    resource_group_name  = "terraformstate"  
    storage_account_name = "sgterraformstate"                      
    container_name       = "tfstate"                       
    key                  = "state.terraform.tfstate"       
  }
}

