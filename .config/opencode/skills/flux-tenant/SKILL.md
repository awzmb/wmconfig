---
name: flux-tenant
description: >
  Review or scaffold Flux tenant GitOps repos of the flux-backstage-infra shape
  (tenants/<project>/*.yaml Flux Kustomizations + infrastructure/<env>/<app>/ manifests,
  Istio mesh, SOPS/GCP KMS secrets, CNPG). Use when the user asks to add an app to a tenant,
  create a new Flux repo or environment, or review manifests for Istio
  VirtualService/ServiceEntry/DestinationRule/AuthorizationPolicy, tenant-gateway,
  privateBaseDomain, postBuild substitution, or sops encryption.
---

A tenant repo is reconciled by Flux into a namespace the tenant does not own cluster-wide.
Most mistakes here are not YAML errors — they are mesh-wide or cross-namespace side effects
that pass `kustomize build` and break other tenants. Check those first.

## Layout

- `tenants/<gcp-project-id>/` — one Flux `Kustomization` per app, `metadata.namespace` =
  tenant namespace, ordered with `dependsOn`. Plus a plain `kustomization.yaml` listing them.
- `infrastructure/<env>/<app>/` — the actual manifests + a kustomize `kustomization.yaml`.
- `.sops.yaml` — one `creation_rules` entry per env, `path_regex` per app dir.

Every app directory is reachable from exactly one Flux Kustomization, and every YAML file in
it is listed in its `kustomization.yaml`. Unlisted files are silently dead — grep for them.

## Hard rules (these are the review findings)

- **Never hardcode a domain.** `backstage.${privateBaseDomain}`, substituted via
  `spec.postBuild.substituteFrom` ConfigMaps `tenant-config` + `cluster-config` (optional).
  Any literal company domain in a manifest is a finding.
- **`ServiceEntry` must set `exportTo: ["."]`.** Without it the host override is mesh-wide
  and hijacks the domain for every workload in the cluster.
- **Ingress gateway is `tenant-gateway`**, never `istio-system/ingressgateway` and never a
  tenant-owned `Gateway` resource.
- **`AuthorizationPolicy` for every exposed workload.** App allows only the proxy's SPIFFE
  principal; the proxy allows only `cluster.local/ns/istio-system/sa/istio-ingressgateway`
  (plus explicit public paths). An app Service reachable without a policy is a finding.
- **`DestinationRule` with `tls.mode: ISTIO_MUTUAL`** for each in-mesh host, including the
  `${privateBaseDomain}` host (there with `subjectAltNames: spiffe://…/sa/<app>`).
- **Pod template needs `sidecar.istio.io/inject: "true"`.**
- **Secrets are SOPS-encrypted** and the app dir matches a `.sops.yaml` `path_regex`; the
  Flux Kustomization needs `decryption: {provider: sops, serviceAccountName: flux-tenant}`.
  A plaintext `stringData` outside a `path_regex` is a leak, not a style issue.
- **No cluster-scoped resources unless deliberate.** `ClusterRole`/`ClusterRoleBinding` have
  no namespace to isolate them — prefix names with the app, and keep them in their own Flux
  Kustomization so pruning cannot reach another tenant's objects.
- **`$${VAR}` in app config** — a single `$` is eaten by Flux postBuild substitution before
  the container ever sees it.
- Flux Kustomizations: `interval: 10m0s`, `retryInterval: 1m0s`, `prune: true`, `wait: true`,
  `targetNamespace`, `sourceRef` the shared `GitRepository`.
- Name everything `<app>-<component>` (`backstage-oauth2-proxy`,
  `backstage-postgresql-credentials`) so a shared namespace stays unambiguous.
- Workload identity is `iam.gke.io/gcp-service-account` on the ServiceAccount; GCP IAM, not
  in-cluster RBAC, is where a tenant's cluster/project read access comes from.

## Scaffolding a new app

Copy the nearest existing app directory, don't write from scratch — the Istio quartet
(ServiceEntry, two DestinationRules, AuthorizationPolicy, VirtualService) is easy to get
half-right. Then: rename, repoint the namespace, add `tenants/<project>/<app>.yaml` with the
right `dependsOn`, list it in both `kustomization.yaml` files, and add the dir to
`.sops.yaml` if it holds secrets.

For a new environment, duplicate `infrastructure/<env>/` and add the `.sops.yaml` rule with
that env's KMS key — the key is per GCP project, copying dev's is a silent decrypt failure.

## Checking

```sh
kustomize build infrastructure/<env>/<app>    # and tenants/<project>
```
`${…}` placeholders are fine here; Flux resolves them, not kustomize. The build proves
nothing about the rules above — read the diff too.

State plainly what was not checked: cluster state, whether `tenant-config` actually defines
the substituted vars, and whether the KMS key is reachable.
