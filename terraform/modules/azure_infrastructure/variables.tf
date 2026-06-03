variable "project_name" {
  type        = string
  default     = "circleguard"
  description = "Nombre base para los recursos"
}

variable "location" {
  type        = string
  default     = "eastus2"
  description = "Región de Azure donde se desplegarán los recursos"
}

variable "acr_name" {
  type        = string
  default     = "circleguardacr"
  description = "Nombre del Container Registry"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Tamaño de las Máquinas Virtuales del Node Pool de AKS"
}
