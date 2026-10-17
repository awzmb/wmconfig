---
name: panos-policy
description: >
  Add or change Panorama firewall policy in the solution-platform--panos-config Terraform repo:
  address objects, address groups, service objects, and security rules for the GCP landing zone.
  Use when the user asks to open/allow traffic, grant a subnet access to something, add a
  firewall rule, add an address object, or mentions Panorama, PAN-OS, panos_panorama_*,
  gcp-dg, or a CR-/SR- ticket for network access.
---

Firewall policy is not code you can iterate on — a wrong object is a security hole or an
outage, and nobody notices for months. Get the facts before writing HCL.

## Before writing anything

1. **Resolve the real CIDRs.** Never infer a subnet's purpose from an object name. Ask the
   user, or have them run `gcloud compute networks subnets describe <name> --project=<p>
   --region=<r>`. That output also names the `pod` and `service` secondary ranges —
   decide explicitly which the traffic needs.
2. **Find the zone**, don't guess it. Match the CIDR against the static routes in
   `modules/networking/networking_vr-*.tf`, then use the matching `var.zone_*`.
3. **Check the object already exists.** Grep `modules/policies/policies_address*.tf` for the
   CIDR before creating a duplicate.
4. **Confirm the ports.** Applications and services are separate fields in PAN-OS; both
   must be right. If the protocol is not obvious, ask rather than guessing "any".

## Writing the change

- Object name `<flattened-cidr>-<name>` (`10.71.192.0/18` → `1071192-gke-platform-dev`),
  `device_group = panos_panorama_device_group.gcp-dg.name`.
- Rule name `<source>_2_<destination>`, `description` = the ticket ID, `log_setting =
  "Forward to Panorama"`, current-year tag (`FW_2026`), append at the end of the rule group
  in `policies_security-rules.tf`.
- One destination → reference the object directly. Two or more → address group.
- Rules are directional. Adding A→B does not allow B→A; say so instead of silently
  assuming return traffic works.
- Never widen an existing rule's zones/addresses to cover a new request; write a new rule.

## Checking

- `tofu fmt -check -diff` on the touched files only — the repo has pre-existing drift and
  a tree-wide `fmt -w` buries the real diff.
- `tofu validate` requires `tofu init` + provider access; when unavailable, grep that every
  referenced `panos_panorama_*` resource name exists exactly once.
- Show the final `git diff HEAD` and state plainly what was *not* covered (reverse
  direction, pod/service ranges, other ports).

## Known facts

- GKE private control plane: **tcp/443 only**. 10250 (kubelet) and 15017 (istio webhook)
  are control-plane → node, a different rule in the opposite direction.
- Databricks control plane in this estate uses tcp/8443-8451, not 443.
- `tofu`, not `terraform`.
