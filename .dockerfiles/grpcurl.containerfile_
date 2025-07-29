FROM docker.io/golang:latest AS build

RUN git clone https://github.com/fullstorydev/grpcurl.git /go/src/grpcurl

WORKDIR /go/src/grpcurl

RUN go mod tidy

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -o /go/bin/grpcurl \
    -ldflags "-w -extldflags \"-static\" \
    ./cmd/grpcurl

FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/grpcurl /usr/local/bin
COPY --from=kubectl /usr/bin/kubectl /usr/bin

ENTRYPOINT ["grpcurl"]
