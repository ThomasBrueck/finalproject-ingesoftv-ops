variable "acr_name" {
  type        = string
  default     = "circleguardacrstage"
  description = "Nombre único del ACR para STAGE (debe ser único en todo Azure)"
}

variable "ssh_public_key" {
  type        = string
  default     = null
  description = "Clave pública SSH. Si es null, se leerá desde ~/.ssh/id_rsa.pub"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2ms"
  description = "Tamaño de la VM en STAGE"
}

variable "postgres_password" {
  type        = string
  default     = "supersecretpassword"
  description = "Contraseña de la base de datos Postgres"
}
