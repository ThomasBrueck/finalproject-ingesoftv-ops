variable "environment" {
  type        = string
  description = "Nombre del ambiente (dev, stage, prod)"
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Región de Azure donde se desplegarán los recursos"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2ms"
  description = "Tamaño de la Máquina Virtual de Azure"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Usuario administrador de la VM"
}

variable "acr_name" {
  type        = string
  description = "Nombre único global para el Azure Container Registry (alfanumérico únicamente)"
}

variable "acr_sku" {
  type        = string
  default     = "Basic"
  description = "SKU de Azure Container Registry (Basic, Standard, Premium)"
}

variable "ssh_public_key" {
  type        = string
  default     = null
  description = "Clave pública SSH para acceder a la VM. Si es null, se leerá desde ~/.ssh/id_rsa.pub"
}
