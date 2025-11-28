variable "resource_group" { default = "weather-rg" }
variable "location" { default = "East US" }
variable "vnet_name" { default = "weather-vnet" }
variable "subnet_name" { default = "weather-subnet" }
variable "nsg_name" { default = "weather-nsg" }
variable "vm_name" { default = "weather-vm" }
variable "admin_username" { default = "weatheruser" }
variable "key_vault_name" { default = "weather-weather-keyvault" }
variable "secret_name" { default = "vm-ssh-key" }

variable "sp_object_id" {
  description = "Object ID of the Service Principal"
  type        = string
}
/*
variable "sp_object_id1" {
  description = "Object ID of the Service Principal"
  type        = string
}
*/
