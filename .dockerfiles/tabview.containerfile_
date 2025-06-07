# builder
FROM docker.io/rust:latest as build

WORKDIR /build

RUN cargo install --git https://github.com/shshemi/tabiew.git --root /usr/local

# runtime
FROM gcr.io/distroless/cc

COPY --from=build /usr/local/bin/tw /bin/tw

ENTRYPOINT ["tw"]
