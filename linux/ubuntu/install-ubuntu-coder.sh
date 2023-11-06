#!/bin/bash

# install baseline packages
DEBIAN_FRONTEND="noninteractive" sudo apt-get install --no-install-recommends --yes \
  bash \
  zsh \
  build-essential \
  ca-certificates \
  curl \
  htop \
  locales \
  man \
  python3 \
  python3-pip \
  software-properties-common \
  sudo \
  systemd \
  systemd-sysv \
  unzip \
  vim \
  neovim \
  wget \
  rsync \
  git

# install additional shell tools
DEBIAN_FRONTEND="noninteractive" sudo apt-get install --no-install-recommends --yes \
  vifm \
  calc \
  bat \
  jq \
  tree \
  ack \
  fd-find \
  fzf \
  tmux \
  ranger \
  gnupg2 \
  w3m \
  exa \
  w3m-img \
  python3-neovim \
  calcurse \
  newsboat \
  neofetch \
  xdg-utils \
  pass

# install openvpn, wireguard and additional networking tools
DEBIAN_FRONTEND="noninteractive" sudo apt-get install --no-install-recommends --yes \
  netcat-openbsd \
  openvpn \
  wireguard

# install vim-plug for vim and neovim
sudo curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim && \
    sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
      https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

# install kubectl
sudo curl -o /usr/local/bin/kubectl \
  -L "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# install gcloud
sudo echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y

# kubernetes tools: kubectx, and kubens
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -O ~/.bin/kubectx && chmod +x ~/.bin/kubectx
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -O ~/.bin/kubens && chmod +x ~/.bin/kubens

# kubernetes tools: helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 && \
  bash get_helm.sh && \
  rm get_helm.sh

# kubernetes tools: krew
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

# create bin dir in home
mkdir -p ~/.bin

# install terraform-ls (usage in vim)
sudo TERRAFORM_LS_VERSION=$(curl -s https://releases.hashicorp.com/terraform-ls/ | grep terraform-ls/ | sed 's/<[^>]*>//g' | sed 's/terraform-ls_//g' | tr -s \\t " " | sort -r | head -n 1 | cut -c 2-) && \
    TERRAFORM_LS_ZIP="terraform-ls_${TERRAFORM_LS_VERSION}_$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/').zip" && \
    wget "https://releases.hashicorp.com/terraform-ls/${TERRAFORM_LS_VERSION}/${TERRAFORM_LS_ZIP}" && \
    unzip ${TERRAFORM_LS_ZIP} && \
    mv terraform-ls ~/.bin/terraform-ls && \
    rm "${TERRAFORM_LS_ZIP}"

# install cilium
CILIUM_VERSION=$(curl -s https://api.github.com/repos/cilium/cilium-cli/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
CILIUM_ARCHIVE="cilium-$(uname | tr '[:upper:]' '[:lower:]')-$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/').tar.gz"
wget https://github.com/cilium/cilium-cli/releases/download/v${CILIUM_VERSION}/${CILIUM_ARCHIVE} && \
tar xf ${CILIUM_ARCHIVE} && \
rm ${CILIUM_ARCHIVE} && \
chmod +x cilium && \
mv cilium ~/.bin/cilium

# install nodejs and yarn (coc.nvim)
DEBIAN_FRONTEND="noninteractive" sudo apt-get --no-install-recommends install --yes \
  nodejs \
  yarn

# install hcloud and aws cli
DEBIAN_FRONTEND="noninteractive" sudo apt-get install --no-install-recommends --yes \
  hcloud-cli \
  awscli

# install fluxcd binary
sudo curl -s https://fluxcd.io/install.sh | bash

# install java development premise
DEBIAN_FRONTEND="noninteractive" sudo apt-get install --no-install-recommends --yes \
  openjdk-17-jdk \
  openjdk-11-jdk \
  maven \
  gradle \
  default-jdk

# install atlassian sdk and set ATLAS_HOME accordingly
sudo curl -o /tmp/atlassian-plugin-sdk.tar.gz -L "https://marketplace.atlassian.com/download/plugins/atlassian-plugin-sdk-tgz" && \
  mkdir -p ~/.sdk/atlassian-sdk && \
  tar xf /tmp/atlassian-plugin-sdk.tar.gz -C \
    ~/.sdk/atlassian-sdk --strip-components=1
echo "export ATLAS_HOME=/app/atlassian-sdk" | sudo tee /etc/profile.d/atlassian-sdk.sh

# set default shell to zsh
sudo chsh -s /bin/zsh && \
echo "export SHELL=/bin/zsh" | sudo tee /etc/profile.d/40zshdefaultshell.sh

# maven settings.xml for atlassian development
mkdir -p ${HOME}/.m2
cp ./maven-settings.xml ${HOME}/.m2/settings.xml
DEBIAN_FRONTEND="noninteractive" sudo apt-get install --no-install-recommends --yes \
  maven

# get custom shell setup from github
#git clone https://github.com/awzmb/wmconfig $HOME/.cfg
#$HOME/.cfg/install || :

# cleanup
sudo apt autoclean
