variable "environments" {
  type        = list(string)
  default     = ["dev", "stage", "prod"]
  description = "Lista de namespaces/ambientes a crear en el clúster"
}
