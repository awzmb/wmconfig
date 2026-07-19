FROM docker.io/debian:bookworm-20250929@sha256:93492d1405a072c9d3b89110490e330e0b7eb37754cafc9520908b7fe6873f5f AS build

RUN apt-get update && apt-get install -y \
  curl \
  unzip \
  tar \
  grep \
  ca-certificates \
  && rm -rf /var/lib/apt/lists/*

ADD ./install-incus-client.sh /tmp/install-incus-client.sh
ADD ./install-minio-client.sh /tmp/install-minio-client.sh

RUN chmod +x /tmp/install-minio-client.sh && /tmp/install-minio-client.sh
RUN chmod +x /tmp/install-incus-client.sh && /tmp/install-incus-client.sh

FROM gcr.io/distroless/static-debian13:latest@sha256:9197324ba51d9cd071af8505989365c006adf9d6d2067eada25aef00abbb5278

COPY --from=build /usr/local/bin/incus /usr/local/bin/incus
COPY --from=build /usr/local/bin/minio /usr/local/bin/minio

ENTRYPOINT ["incus"]
