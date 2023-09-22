# get architecture and os
if [ -z "${OS}" ]; then
  OS=$(uname)
fi
case ${OS} in
  Darwin)
    OS=darwin
    ;;
  Linux)
    OS=linux
    ;;
  *)
    fatal "Unsupported operating system ${OS}"
esac

if [ -z "${ARCH}" ]; then
  ARCH=$(uname -m)
fi
case ${ARCH} in
  arm|armv6l|armv7l)
    ARCH=arm
    ;;
  arm64|aarch64|armv8l)
    ARCH=arm64
    ;;
  amd64)
    ARCH=amd64
    CHECTL_ARCH=x64
    ;;
  x86_64)
    ARCH=amd64
    CHECTL_ARCH=x64
    ;;
  *)
    fatal "Unsupported architecture ${ARCH}"
esac

INSTALL_DIR=${HOME}/.bin


# terraform
TERRAFORM_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TERRAFORM_ZIP="terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip"
wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TERRAFORM_ZIP}
unzip ${TERRAFORM_ZIP}
sudo mv terraform ${INSTALL_DIR}
rm ${TERRAFORM_ZIP}

# terraform language server
TERRAFORM_LS_VERSION=$(curl -s https://releases.hashicorp.com/terraform-ls/ | grep terraform-ls/ | sed 's/<[^>]*>//g' | sed 's/terraform-ls_//g' | tr -s \\t " " | sort -r | head -n 1 | cut -c 2-)
TERRAFORM_LS_ZIP="terraform-ls_${TERRAFORM_LS_VERSION}_${OS}_${ARCH}.zip"
wget "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/${TERRAFORM_LS_ZIP}"
unzip ${TERRAFORM_LS_ZIP}
mv terraform-ls ${INSTALL_DIR}
rm "${TERRAFORM_LS_ZIP}"

# install terragrunt
TERRAGRUNT_VERSION=$(curl -s https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
TERRAGRUNT_BINARY="terragrunt_${OS}_${ARCH}"
wget https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/${TERRAGRUNT_BINARY}
chmod +x ${TERRAGRUNT_BINARY}
mv ${TERRAGRUNT_BINARY} ${INSTALL_DIR}

# install cilium
CILIUM_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
CILIUM_ARCHIVE="cilium-${OS}-${ARCH}.tar.gz"
wget https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_VERSION}/${CILIUM_ARCHIVE}
tar xf ${CILIUM_ARCHIVE}
rm ${CILIUM_ARCHIVE}
chmod +x cilium
mv cilium ${INSTALL_DIR}

CMCTL_VERSION=$(curl -s https://api.github.com/repos/cert-manager/cert-manager/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
CMCTL_ARCHIVE="cmctl-${OS}-${ARCH}.tar.gz"
wget https://github.com/cert-manager/cert-manager/releases/download/v${CMCTL_VERSION}/${CMCTL_ARCHIVE}
tar xf ${CMCTL_ARCHIVE}
rm ${CMCTL_ARCHIVE}
chmod +x cmctl
mv cmctl ${INSTALL_DIR}

# chectl to install eclipse che
#CHECTL_VERSION=$(curl -s https://api.github.com/repos/che-incubator/chectl/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
#CHECTL_ARCHIVE="chectl-${OS}-${CHECTL_ARCH}.tar.gz"
#wget https://github.com/che-incubator/chectl/releases/download/${CHECTL_VERSION}/${CHECTL_ARCHIVE}
#tar xf ${CHECTL_ARCHIVE}
#rm ${CHECTL_ARCHIVE}
#chmod +x chectl
#mv chectl ${INSTALL_DIR}
bash <(curl -sL  https://www.eclipse.org/che/chectl/) --channel=next

# install fluxcd binary
#curl -s https://fluxcd.io/install.sh | sudo bash
