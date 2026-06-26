# mykola_kharchenko.mailstack

An Ansible collection that **builds and operates a self-hosted mail server** on
Fedora and RHEL in **image mode (bootc)**. It provisions a complete, modern mail
stack with a single Rspamd-based filtering pipeline, managed entirely through
native `systemd` units — no supervisord, no in-container process manager.

The same roles also run on package-mode (mutable) Fedora/RHEL hosts, so a single
codebase covers both image-mode and traditional deployments.

## Components

| Service | Role |
|---|---|
| **Postfix** | MTA — inbound/outbound SMTP, submission (587/465) |
| **Dovecot** | IMAP/POP3, LMTP delivery, mailbox storage, Sieve |
| **Rspamd** | Spam scoring, DKIM signing, DMARC, ARC, greylisting, milter |
| **ClamAV** | Virus scanning (driven by Rspamd) |
| **Valkey** | Backend for Rspamd statistics, greylisting, ratelimits |
| **Fail2ban** | Brute-force protection on SMTP/IMAP auth |

Filtering is **Rspamd-only by design**. Amavis, SpamAssassin, OpenDKIM and
OpenDMARC are intentionally excluded — Rspamd covers signing, policy and scanning
in one daemon, which also avoids the EPEL/libdb licensing friction those packages
carry on RHEL 10.

## Design principles

- **Fedora-first, RHEL-compatible.** Both targets are `os_family == RedHat`, so
  the bulk of the logic (dnf, systemd, SELinux, firewalld) is shared. All
  distribution divergence is isolated to a single `repos` role plus
  `vars/<distribution>.yml` package maps.
- **bootc-aware split.** Operations are cleanly separated into **build-time**
  (image construction) and **runtime** (machine-local state), matching the
  immutable `/usr` + persistent `/etc` and `/var` model of bootc.
- **systemd-native.** Each service is a real unit, enabled in the image. No
  custom entrypoint or runtime config generation.
- **SELinux enforcing.** Targeted policy and booleans (e.g.
  `antivirus_can_scan_system`, `antivirus_use_jit`) are configured rather than
  disabled.

## Operations model

### Day-1 — install & initial provisioning

Day-1 is **build-time**. The collection's `build` playbook is invoked from a
`Containerfile` with a local connection, producing an immutable bootc image:

- Enable required repositories
  (Fedora: base repos only; RHEL: CodeReady Builder + EPEL + the upstream Rspamd
  repository).
- Install and configure Postfix, Dovecot, Rspamd, ClamAV, Valkey, Fail2ban.
- Lay down base configuration and `systemctl enable` all units.
- Apply SELinux policy and booleans; open firewall ports.

Initial deployment configuration — primary domain(s), the first mailbox(es),
DKIM keypairs and TLS material — is applied on **first boot** (or baked in, for
fully declarative images).

> Package installation never happens at runtime on a bootc host. New packages or
> base-config changes are delivered by rebuilding the image and rolling it out
> with `bootc upgrade` / `bootc switch`.

### Day-2 — ongoing configuration & management

Day-2 is **runtime**. The `provision` playbook manages machine-local state that
lives in the persistent parts of the filesystem (`/etc`, `/var`) and therefore
survives transactional image updates:

- Add / remove **domains**, **mailboxes**, **aliases**.
- Generate and **rotate DKIM keys**; publish the matching DNS records.
- Renew / replace **TLS certificates**.
- Tune Rspamd policy, greylisting and ratelimits.

All day-2 tasks are idempotent and touch only `/etc` and `/var` — the immutable
`/usr` tree is never modified.

## Supported platforms

| Platform | Base image | Notes |
|---|---|---|
| **Fedora bootc** | `quay.io/fedora/fedora-bootc` | Public registry; all packages from base repos |
| **RHEL bootc** | `registry.redhat.io/rhel10/rhel-bootc` | Requires Red Hat entitlement / pull secret; CRB + EPEL + upstream Rspamd repo |

> RHEL 10's current minor stream is **10.2**; image mode is the supported
> deployment model. Earlier minors (e.g. 10.0 EUS) work with the same roles —
> only the base image reference changes.

## Requirements

- `ansible-core` on the control/build node
- Collections: `ansible.posix` (SELinux, mounts), `community.general`,
  `community.crypto` (DKIM/TLS key material)
- For RHEL builds: a valid subscription / registry pull secret
- For image builds: `podman` (or `buildah`) and `bootc`

## Layout

```
mykola_kharchenko.mailstack
├── galaxy.yml
├── roles/
│   ├── repos        # the only distribution-divergent role
│   ├── postfix
│   ├── dovecot
│   ├── rspamd
│   ├── clamav
│   ├── valkey
│   └── fail2ban
└── playbooks/
    ├── build.yml        # day-1, build-time (Containerfile)
    └── provision.yml    # day-2, runtime
```

## Non-goals

- Webmail UI (Roundcube, SOGo, …)
- Groupware / calendaring / ActiveSync — this is **not** an Exchange replacement
- Bundled DNS authority — DKIM/SPF/DMARC records are emitted for you to publish

## License

GPL-3.0-or-later
