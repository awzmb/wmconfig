FROM cgr.dev/chainguard/wolfi-base:latest@sha256:02dab76bd852a70556b5b2002195c8a5fdab77d323c433bf6642aab080489795

# Layer 1: System Packages & Setup
# Wolfi ships apk with the signing keys and repo preconfigured, so no
# keyring bootstrap is needed (unlike the previous Arch base).
RUN apk add --no-cache \
  # --- Core Development Tools ---
  bash \
  build-base \
  cmake \
  curl \
  delta \
  fd \
  fzf \
  git \
  git-crypt \
  git-lfs \
  gnupg \
  jq \
  neovim \
  openssl \
  tree-sitter \
  # posix-libc-utils ships getconf/ldd — Mason uses them to detect glibc
  # vs musl; without them it reports "platform unsupported" for prebuilt
  # binaries (rust-analyzer, lua-language-server, helm-ls, …).
  posix-libc-utils \
  ripgrep \
  shadow \
  unzip \
  wget \
  wl-clipboard \
  yq \
  zsh \
  # --- Language Support: Java ---
  openjdk-26 \
  openjdk-26-default-jdk \
  # --- Language Support: Javascript/TypeScript ---
  # npm is for Mason.nvim, which hardcodes it (spawn.npm) for node-based
  # language servers. pnpm/yarn are here for your own project work.
  nodejs \
  npm \
  pnpm \
  yarn \
  # --- Language Support: Lua (for Neovim) — luarocks pulls luajit;
  #     luajit-dev provides lua.h so luarocks can build C rocks
  #     (luafilesystem, a luacheck dep). luacheck itself is installed by
  #     Mason below. ---
  luajit-dev \
  luarocks \
  # --- Language Support: Python ---
  # py3-pip stays: Mason.nvim's pypi installer runs `python -m venv
  # --system-site-packages` + `python -m pip`, so the system pip must be
  # importable inside the venv. uv is for your own project work.
  python3 \
  py3-pip \
  uv \
  # --- Language Support: Rust (rustup-init bootstraps the toolchain per
  #     user below) ---
  rustup \
  # --- Language Support: Golang (gopls installed by Mason below) ---
  go \
  # --- Language Support: Terraform/Terragrunt ---
  terraform \
  opentofu \
  terragrunt

# terraform-ls: install the latest release from HashiCorp directly (Mason's
# prebuilt musl binary is unreliable on Wolfi). Runs as root -> /usr/bin.
RUN set -eu; \
  ARCH=$(uname -m); \
  case ${ARCH} in \
  arm|armv6l|armv7l) ARCH=arm ;; \
  arm64|aarch64|armv8l) ARCH=arm64 ;; \
  amd64|x86_64) ARCH=amd64 ;; \
  *) echo "Unsupported architecture ${ARCH}" >&2; exit 1 ;; \
  esac; \
  TMP_DIR=$(mktemp -d); \
  VERSION=$(curl -s https://releases.hashicorp.com/terraform-ls/ | grep terraform-ls/ | sed 's/<[^>]*>//g;s/terraform-ls_//g' | tr -s '\t' ' ' | sort -r | head -n 1 | cut -c 2-); \
  ARCHIVE="terraform-ls_${VERSION}_$(uname -s | tr '[:upper:]' '[:lower:]')_${ARCH}.zip"; \
  curl -L --output "${TMP_DIR}/${ARCHIVE}" --url "https://releases.hashicorp.com/terraform-ls/${VERSION}/${ARCHIVE}"; \
  unzip "${TMP_DIR}/${ARCHIVE}" -d "${TMP_DIR}"; \
  mv "${TMP_DIR}/terraform-ls" /usr/bin/terraform-ls; \
  chmod +x /usr/bin/terraform-ls; \
  rm -rf "${TMP_DIR}"; \
  terraform-ls --version

# tree-sitter CLI: the wolfi `tree-sitter` apk ships only the C library, not
# the Rust CLI binary that nvim-treesitter's `main` branch shells out to
# (`tree-sitter build`). Grab the prebuilt release binary (wolfi is glibc)
# pinned to the library version for a reproducible, compile-free install.
RUN set -eu; \
  TS_VERSION=0.26.11; \
  case $(uname -m) in \
  arm64|aarch64) TS_ARCH=arm64 ;; \
  amd64|x86_64) TS_ARCH=x64 ;; \
  *) echo "Unsupported architecture $(uname -m)" >&2; exit 1 ;; \
  esac; \
  curl -L "https://github.com/tree-sitter/tree-sitter/releases/download/v${TS_VERSION}/tree-sitter-linux-${TS_ARCH}.gz" \
  | gunzip > /usr/bin/tree-sitter; \
  chmod +x /usr/bin/tree-sitter; \
  tree-sitter --version

# Java isn't on PATH by default on Wolfi; expose it for the user's own work.
ENV JAVA_HOME="/usr/lib/jvm/java-26-openjdk"
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Layer 2: Create a non-root user for better security and permissions
# User will have the same UID/GID as a typical default user on Linux (1000)
# This can be overridden at build time with --build-arg USER_ID=xxx --build-arg GROUP_ID=xxx
# NOTE: If running into problems, check your current UID/GID with `id -u` and `id -g`
ARG USER_ID=1000
ARG GROUP_ID=1000
ARG USERNAME=dev
RUN groupadd --gid $GROUP_ID ${USERNAME} && \
  useradd --uid $USER_ID --gid $GROUP_ID -m -s /usr/bin/zsh ${USERNAME}

# Switch to the new user
USER ${USERNAME}
WORKDIR /home/${USERNAME}

# Configure User Environment (Git, Rust)
RUN \
  # Configure git alias for the user
  git config --global alias.graph "log --graph --abbrev-commit --decorate --format=format:'%C(bold blue)%h%C(reset) - %C(bold green)(%ar)%C(reset) %C(white)%s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%C(reset)'" && \
  # Install the default Rust toolchain. Wolfi ships `rustup-init` (not
  # `rustup`); running it populates ~/.cargo/bin with rustup/cargo/rustc.
  rustup-init -y --profile minimal --default-toolchain stable

# Add Rust's cargo bin to the PATH
ENV PATH="/home/${USERNAME}/.cargo/bin:${PATH}"

# Pre-install Neovim plugins
# Bake in the local Neovim config from ./config (init.lua + lazy-lock.json).
# lazy-lock.json pins plugin commits so the headless sync below is reproducible.
COPY --chown=${USERNAME}:${USERNAME} config/ /home/${USERNAME}/.config/nvim/

# Install lazy.nvim plugin manager
RUN git clone --filter=blob:none https://github.com/folke/lazy.nvim.git --branch=stable /home/${USERNAME}/.local/share/nvim/lazy/lazy.nvim

# Install plugins at the exact commits pinned in lazy-lock.json (restore
# honors the lockfile; sync would update and drift from it).
RUN nvim --headless "+Lazy! restore" "+qa"

# Point luarocks at luajit's C headers so Mason can build C rocks
# (luafilesystem for luacheck). Wolfi's luarocks otherwise looks in the
# non-existent /usr/include/lua/5.1.
RUN luarocks config variables.LUA_INCDIR /usr/include/luajit-2.1 && \
  luarocks config variables.LUA_LIBDIR /usr/lib

# Install Mason packages
# RUN nvim --headless +"lua require('nvchad.mason').install_all()" +"autocmd User MasonUpdateAllComplete qa"
RUN nvim --headless -c "MasonInstall lua-language-server rust-analyzer helm-ls pyright gopls yaml-language-server dockerfile-language-server json-lsp bash-language-server tflint tfsec luacheck kube-linter hclfmt" -c qall

# Set the default working directory for the container
WORKDIR /workspace

# Default command to start Neovim
CMD ["/usr/bin/nvim"]
