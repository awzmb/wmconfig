FROM docker.io/golang:latest AS build

RUN go install github.com/minamijoyo/tfupdate@latest

FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/tfupdate /usr/local/bin/tfupdate

ENTRYPOINT ["/usr/local/bin/tfupdate"]
