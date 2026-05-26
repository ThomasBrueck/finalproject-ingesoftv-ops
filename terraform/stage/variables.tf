variable "location" {
  description = "The Azure region for the stage environment."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group for the stage environment."
  type        = string
  default     = "finalproject-rg-stage"
}
