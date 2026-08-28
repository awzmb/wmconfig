# Environment

You run inside a rootless container, not on the user's machine.
Consequences:

- The filesystem, processes and network you see are the container's, not the host's.
  You cannot inspect, change or restart anything on the host.
- You are the non-root user `dev`. There is no `sudo`. `apk add` will fail — do not
  try to install system packages. If a tool is missing, say so and suggest adding it
  to the Dockerfile instead of working around it.
- There is no Docker daemon, no systemd, no kubectl and no cluster access unless the
  user has explicitly mounted credentials.
- Anything outside the mounted working directory is throwaway and disappears when the
  container exits.
- Network access is restricted to the hosts in `allowedUrls` in `settings.json`.

# Available tools

Only these are installed (from the Dockerfile). Assume nothing else exists:

`bash`, `curl`, `ca-certificates`, `openssl`, `git`, `gh`, `copilot`,
`make`, `cmake`, `gcc`, `glibc`, `go`, `golangci-lint`,
`rust` (`cargo`, `rustc`), `rust-analyzer`,
`nodejs` (`node`, `npm`), `yarn`, `uv`, `python3`
`helm`, `helm-docs`, `kustomize`, `opentofu` (`tofu`), `terragrunt`,
`jq`, `yq`, `tzdata`, `shadow`.

Notes:
- Terraform is **not** installed — use `tofu`.
- Python is **not** installed as a system package — use `uv run` / `uv python install`.
- Check with `command -v <tool>` before assuming; the Dockerfile is the source of truth.
