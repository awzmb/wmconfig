# builder
FROM docker.io/rust:1.90.0@sha256:512d81e488da6ba3e88637340fa84decd29293185d48e4708468e1b1d3bb20a9 as build

WORKDIR /build

RUN cargo install --git https://github.com/shshemi/tabiew.git --root /usr/local

# runtime
FROM gcr.io/distroless/cc:latest@sha256:14f6999db515330e5d00537bd457289a8968b6456e9197c7a28101ee63a7522f

COPY --from=build /usr/local/bin/tw /bin/tw

ENTRYPOINT ["tw"]
