module "jenkins_vm" {
  source         = "../../modules/jenkins_vm"
  ssh_public_key = var.ssh_public_key
  vm_size        = var.vm_size
}

output "jenkins_url" {
  value       = module.jenkins_vm.jenkins_url
  description = "Abre esta URL en el navegador para acceder a Jenkins"
}

output "sonarqube_url" {
  value       = module.jenkins_vm.sonarqube_url
  description = "Abre esta URL en el navegador para acceder a SonarQube"
}

output "ssh_command" {
  value       = module.jenkins_vm.ssh_command
  description = "Comando para conectarse a la VM vía SSH"
}

output "vm_name" {
  value       = module.jenkins_vm.vm_name
}

output "resource_group" {
  value       = module.jenkins_vm.resource_group
}
