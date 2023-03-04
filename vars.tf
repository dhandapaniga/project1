# Hi, Two parking lots are available both covered.
# 1. at Block B Parking Lot (Ground Floor) - 250RM
# 2. at Block C Parking Lot (One Floor down) - 200RM
# Three months deposit. 1 months contract. Deposit will be returned at the end of contract.

variable "vm_count" {
  type    = number
  default = 3
}

variable "prefix" {
  description = "this will be the environment name creator"
  default     = "g-project1"
  type        = string
}

variable "azurerm_resource_group" {
  description = "resource group name from the udacity"
  default     = "Azuredevops"
  type        = string
}
