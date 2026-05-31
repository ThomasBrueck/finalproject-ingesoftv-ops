module "kubernetes_services" {
  source = "../../modules/kubernetes_services"

  # Creamos los 3 ambientes en el mismo AKS
  environments = ["dev", "stage", "prod"]
}
