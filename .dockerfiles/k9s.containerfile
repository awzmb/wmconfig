FROM docker.io/golang:latest AS build

RUN git clone https://github.com/derailed/k9s /go/src/k9s

WORKDIR /go/src/k9s

RUN go clean --testcache && go test

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/k9s main.go

FROM cgr.dev/chainguard/kubectl as kubectl

FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/k9s /usr/local/bin
COPY --from=kubectl /usr/bin/kubectl /usr/bin

ENTRYPOINT ["k9s"]
