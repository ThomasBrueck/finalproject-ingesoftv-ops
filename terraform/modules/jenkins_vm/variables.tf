variable "project_name" {
  type        = string
  default     = "circleguard"
  description = "Nombre base para los recursos"
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Región de Azure"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Tamaño de la VM (Standard_B2s = 2 vCPU / 4GB RAM, mínimo para Jenkins + SonarQube)"
}

variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Usuario administrador de la VM"
}

variable "ssh_public_key" {
  type        = string
  description = "Llave SSH pública para acceso a la VM (contenido de ~/.ssh/id_rsa.pub)"
}
