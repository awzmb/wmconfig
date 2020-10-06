# terraform
TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TERRAFORM_BINARY="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_BINARY}
unzip ${TERRAFORM_BINARY}
sudo mv terraform /usr/local/bin
rm ${TERRAFORM_BINARY}

# terraform language server
TERRAFORM_LS_VERSION=$(curl -s https://releases.hashicorp.com/terraform-ls/ | grep terraform-ls/ | sed 's/<[^>]*>//g' | sed 's/terraform-ls_//g' | tr -s \\t " " | sort -r | head -n 1 | cut -c 2-)
TERRAFORM_LS_BINARY="terraform-ls_${TERRAFORM_LS_VERSION}_linux_amd64.zip"
wget "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/${TERRAFORM_LS_BINARY}"
unzip ${TERRAFORM_LS_BINARY}
sudo mv terraform-ls /usr/local/bin
rm "${TERRAFORM_LS_BINARY}"
