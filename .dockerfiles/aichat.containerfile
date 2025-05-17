# builder
#FROM cgr.dev/chainguard/rust as build

#RUN cargo install aichat --version 0.28.0

FROM docker.io/alpine:3.21.3 AS build

RUN apk add --no-cache curl tar

WORKDIR /download

RUN ARCH=$(uname -m) && \
    case ${ARCH} in \
      arm64|aarch64|armv8l) ARCH=aarch64 ;; \
      arm) ARCH=arm ;; \
      armv7) ARCH=armv7 ;; \
      i686) ARCH=i686 ;; \
      amd64|x86_64) ARCH=x86_64 ;; \
      *) echo "Unsupported architecture ${ARCH}" && exit 1 ;; \
    esac && \
    mkdir -p /usr/local/bin && \
    OS=$(uname -s | tr '[:upper:]' '[:lower:]') && \
    AICHAT_VERSION=$(curl -s https://api.github.com/repos/sigoden/aichat/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1') && \
    AICHAT_ARCHIVE="aichat-v${AICHAT_VERSION}-${ARCH}-unknown-${OS}-musl.tar.gz" && \
    curl -L --output "/download/${AICHAT_ARCHIVE}" --url "https://github.com/sigoden/aichat/releases/download/v${AICHAT_VERSION}/${AICHAT_ARCHIVE}" && \
    tar xf /download/${AICHAT_ARCHIVE} -C /download && \
    mv /download/aichat /usr/local/bin && \
    chmod +x /usr/local/bin/aichat

FROM gcr.io/distroless/cc

COPY --from=build /usr/local/bin/aichat /bin/aichat

ENTRYPOINT ["aichat"]
