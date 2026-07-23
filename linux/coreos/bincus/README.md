# prepare incus for `incus remote add
- incus config trust add <insert name>

# connect from remote client
- incus remote add <name> <incus ip>
- incus remote switch <name>

# terraform
- manually create statefile bucket in default project
```
incus storage bucket create default terragrunt-state
```

# add additional image sources
> [!NOTE]: execute this both on the host and the remote client if you are using one)
- incus remote add --protocol oci <name> <url e.g. https://docker.io>
```
incus remote add --protocol oci docker.io https://docker.io
incus remote add --protocol oci gcr.io https://gcr.io
incus remote add --protocol oci ghcr.io https://ghcr.io
```

# forwarding after provisioning a load balancer
- sudo incus config device add oci-test http-proxy proxy listen=tcp:0.0.0.0:80 connect=tcp:10.0.1.1:80
