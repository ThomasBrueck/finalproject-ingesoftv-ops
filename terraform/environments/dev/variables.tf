variable "acr_name" {
  type        = string
  default     = "circleguardacrdev"
  description = "Nombre único del ACR para DEV (debe ser único en todo Azure)"
}

variable "ssh_public_key" {
  type        = string
  default     = null
  description = "Clave pública SSH. Si es null, se leerá desde ~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Tamaño de la VM en DEV"
}

variable "postgres_password" {
  type        = string
  default     = "supersecretpassword"
  description = "Contraseña de la base de datos Postgres"
}
