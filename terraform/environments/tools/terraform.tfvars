# Pega aquí el contenido de tu llave pública SSH:
#   cat ~/.ssh/id_rsa.pub
# Si no tienes una: ssh-keygen -t rsa -b 4096 -C "circleguard-jenkins"
ssh_public_key = "REEMPLAZA_CON_TU_LLAVE_SSH_PUBLICA"

# Standard_B2s  = 2 vCPU / 4GB RAM (~$0.04/h) — mínimo funcional
# Standard_B2ms = 2 vCPU / 8GB RAM (~$0.08/h) — más cómodo para SonarQube
vm_size = "Standard_B2s"
