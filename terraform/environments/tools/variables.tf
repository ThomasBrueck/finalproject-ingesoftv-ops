variable "ssh_public_key" {
  type        = string
  description = "Contenido de tu llave SSH pública (~/.ssh/id_rsa.pub)"
}

variable "vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Tamaño de la VM. Standard_B2s (4GB) es el mínimo; Standard_B2ms (8GB) es más cómodo"
}
