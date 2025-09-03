FROM docker.io/golang:latest AS build

RUN git clone https://github.com/gruntwork-io/terragrunt-ls.git /go/src/terragrunt-ls

WORKDIR /go/src/terragrunt-ls

RUN go clean --testcache && go test --cover ./...

RUN CGO_ENABLED=0 GOOS=$(uname | tr '[A-Z]' '[a-z]') go build -a -o /go/bin/terragrunt-ls main.go

FROM gcr.io/distroless/static-debian12

COPY --from=build /go/bin/terragrunt-ls /usr/local/bin

ENTRYPOINT ["terragrunt-ls"]
