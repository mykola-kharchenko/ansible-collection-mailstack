# Building and rolling out the bootc image

This collection produces an **immutable bootc image** at build time (day-1) and
manages machine-local state at runtime (day-2). This document covers day-1.

## Prerequisites

- `podman` (or `buildah`) and `bootc`
- For RHEL bases: a valid Red Hat entitlement / registry pull secret

## Build (Fedora)

```bash
podman build -t localhost/mailstack-bootc .
```

The `Containerfile` installs `ansible-core` as build-time-only tooling, builds
and installs this collection plus its dependencies, runs the day-1
`build.yml` playbook (`mailstack_start_services=false` — units are enabled, not
started), then removes the tooling so it never ships in the image.

## Build (RHEL)

Override the base image and build on an entitled host:

```bash
podman build \
  --build-arg BASE_IMAGE=registry.redhat.io/rhel10/rhel-bootc:10.2 \
  -t localhost/mailstack-bootc .
```

The `repos` role enables CodeReady Builder + EPEL and adds the upstream Rspamd
repository for RHEL targets.

## Push and roll out

```bash
podman push localhost/mailstack-bootc <registry>/mailstack-bootc:latest
```

On the target host:

```bash
# First-time conversion of an existing bootc host:
bootc switch <registry>/mailstack-bootc:latest

# Subsequent updates:
bootc upgrade
```

## What is baked in vs applied later

| Baked at build (day-1) | Applied at runtime (day-2) |
|---|---|
| Packages, base config, enabled units | Domains, mailboxes, aliases |
| SELinux booleans, firewall ports | DKIM keys + DNS records |
| ClamAV signature DB seed | TLS certificates |

Day-2 configuration is applied with `playbooks/provision.yml` against the
running host — see the role defaults for the variable shapes.
