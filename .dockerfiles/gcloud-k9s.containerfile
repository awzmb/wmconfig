FROM cgr.dev/chainguard/go:latest AS build

RUN git clone https://github.com/derailed/k9s /go/src/k9s

WORKDIR /go/src/k9s

RUN go clean --testcache && go test

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/k9s main.go

FROM gcr.io/google.com/cloudsdktool/google-cloud-cli:latest

RUN apt-get install google-cloud-sdk-gke-gcloud-auth-plugin

COPY --from=build /go/bin/k9s /usr/local/bin

ENTRYPOINT ["/usr/local/bin/k9s"]
