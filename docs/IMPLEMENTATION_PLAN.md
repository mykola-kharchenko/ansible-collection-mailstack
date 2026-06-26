# Implementation plan — `mykola_kharchenko.mailstack`

A step-by-step build order for the collection, expressed as a sequence of
commits. The end goal is a **bootc** image-mode mail server; every step moves
toward a buildable image and an idempotent day-2 runtime.

Each entry below maps to **one commit**. The subject follows Conventional
Commits (`type(scope): summary`); the body explains intent and the concrete
files touched. Types used:

- `chore` — scaffolding, tooling, build infra
- `feat` — roles and playbooks (user-facing capability)
- `ci`   — pipeline config
- `docs` — documentation
- `test` — molecule / verification

Roles are implemented in **runtime-dependency order** so that each new role can
be smoke-tested against the ones already in place:
`repos → valkey → rspamd → clamav → postfix → dovecot → fail2ban`.

---

## Phase 0 — Repository foundation

### Commit 1
```
chore(repo): scaffold collection skeleton and metadata

Lay down the Ansible collection structure so `ansible-galaxy collection
build` succeeds against an empty-but-valid tree.

- galaxy.yml          # namespace mykola_kharchenko, name mailstack, deps
- meta/runtime.yml    # requires_ansible
- LICENSE             # GPL-3.0-or-later
- README.md           # move the existing overview in as the canonical README
- .gitignore          # *.tar.gz build artifacts, .cache, molecule junk
- requirements.yml    # ansible.posix, community.general, community.crypto
```

### Commit 2
```
chore(repo): add editor, lint, and ansible config

Pin formatting and runtime behaviour so every later commit is linted the
same way locally and in CI.

- .editorconfig       # 2-space yaml, lf, trailing newline
- .yamllint           # relaxed line-length, document-start enforced
- .ansible-lint       # production profile, skip rules we consciously accept
- ansible.cfg         # stdout_callback, roles_path, retry/log settings
```

### Commit 3
```
ci(github): lint and sanity on push and PR

Run yamllint + ansible-lint, then collection build, on every push and
pull request. No host provisioning yet — fast feedback only.

- .github/workflows/lint.yml
```

---

## Phase 1 — Distribution divergence

### Commit 4
```
feat(repos): isolate distribution-divergent repository setup

The single role allowed to branch on distribution. Everything else stays
shared across Fedora and RHEL.

- roles/repos/tasks/main.yml      # dispatch on ansible_distribution
- roles/repos/tasks/fedora.yml    # base repos only (no-op / assert)
- roles/repos/tasks/rhel.yml      # enable CRB, install EPEL, add Rspamd repo
- roles/repos/vars/Fedora.yml
- roles/repos/vars/RedHat.yml     # RHEL package/repo names
- roles/repos/defaults/main.yml   # mailstack_rspamd_repo_url, toggles
- roles/repos/meta/main.yml       # galaxy_info, min_ansible_version
```

---

## Phase 2 — Backend and filtering core

### Commit 5
```
feat(valkey): install and enable the Valkey backend

Rspamd's state store (statistics, greylisting, ratelimits). Brought up
first because Rspamd depends on it at runtime.

- roles/valkey/tasks/main.yml     # install, drop config, enable unit
- roles/valkey/defaults/main.yml  # bind address, port, maxmemory policy
- roles/valkey/templates/valkey.conf.j2
- roles/valkey/handlers/main.yml  # restart valkey
- roles/valkey/meta/main.yml
```

### Commit 6
```
feat(rspamd): install Rspamd with milter, DKIM, and Valkey wiring

The single filtering daemon: scoring, DKIM signing, DMARC/ARC,
greylisting. Points at the Valkey role from commit 5.

- roles/rspamd/tasks/main.yml
- roles/rspamd/defaults/main.yml          # scores, milter socket, redis host
- roles/rspamd/templates/local.d/*.j2     # redis.conf, milter_headers, dkim_signing
- roles/rspamd/templates/worker-*.inc.j2  # normal, controller, proxy(milter)
- roles/rspamd/handlers/main.yml
- roles/rspamd/meta/main.yml              # dependency: valkey
```

### Commit 7
```
feat(clamav): install ClamAV and wire it to Rspamd

Virus scanning driven by Rspamd's antivirus module. Configures freshclam
and the SELinux booleans that let clamd scan the mail spool.

- roles/clamav/tasks/main.yml
- roles/clamav/tasks/selinux.yml      # antivirus_can_scan_system, antivirus_use_jit
- roles/clamav/defaults/main.yml
- roles/clamav/templates/clamd.conf.j2
- roles/clamav/handlers/main.yml
- roles/rspamd/templates/local.d/antivirus.conf.j2   # add clamav scanner block
- roles/clamav/meta/main.yml
```

---

## Phase 3 — MTA and delivery

### Commit 8
```
feat(postfix): configure Postfix MTA with submission and milter

Inbound/outbound SMTP plus submission on 587/465, handing mail to the
Rspamd milter and to Dovecot LMTP for local delivery.

- roles/postfix/tasks/main.yml
- roles/postfix/defaults/main.yml         # myhostname, relay, milter socket
- roles/postfix/templates/main.cf.j2
- roles/postfix/templates/master.cf.j2    # submission, smtps, lmtp transport
- roles/postfix/handlers/main.yml
- roles/postfix/meta/main.yml             # dependency: rspamd
```

### Commit 9
```
feat(dovecot): configure Dovecot IMAP/POP3, LMTP, SASL, and Sieve

Mailbox storage, IMAP/POP3 access, LMTP endpoint for Postfix, SASL auth
for submission, and Sieve for server-side filtering.

- roles/dovecot/tasks/main.yml
- roles/dovecot/defaults/main.yml
- roles/dovecot/templates/conf.d/*.j2    # 10-mail, 10-auth, 10-master, 15-lda, 20-lmtp
- roles/dovecot/templates/sieve/*.j2
- roles/dovecot/handlers/main.yml
- roles/dovecot/meta/main.yml
```

---

## Phase 4 — Hardening

### Commit 10
```
feat(fail2ban): add brute-force protection for SMTP and IMAP auth

Jails watching Postfix/Dovecot auth failures. Implemented last so its
filters can target the log formats the other roles actually emit.

- roles/fail2ban/tasks/main.yml
- roles/fail2ban/defaults/main.yml
- roles/fail2ban/templates/jail.local.j2
- roles/fail2ban/templates/filter.d/*.j2
- roles/fail2ban/handlers/main.yml
- roles/fail2ban/meta/main.yml
```

### Commit 11
```
feat(firewall): open mail service ports via firewalld

Centralise port exposure (25, 465, 587, 143, 993, 110, 995) so the build
image presents a consistent, minimal surface.

- roles/<each>/tasks/firewall.yml   # or a shared tasks file included per role
- documented in each role's defaults (mailstack_*_firewall_ports)
```

---

## Phase 5 — Day-1 build (bootc)

### Commit 12
```
feat(playbooks): add day-1 build playbook

Orchestrates the build-time provisioning: repos, then all service roles,
with `systemctl enable` for every unit. Designed for a local connection
inside a Containerfile.

- playbooks/build.yml      # hosts: localhost, connection: local
```

### Commit 13
```
chore(image): add Containerfile to produce the bootc image

Build the immutable image from fedora-bootc / rhel-bootc, running the
day-1 playbook with ansible-core, then stripping build-only tooling.

- Containerfile            # FROM quay.io/fedora/fedora-bootc, RUN ansible-playbook build.yml
- build/                   # any kickstart/entitlement helpers
- docs/building.md         # podman build + bootc switch walkthrough
```

---

## Phase 6 — Day-2 runtime (provision)

### Commit 14
```
feat(playbooks): add day-2 provision playbook entrypoint

Runtime management against the persistent filesystem (/etc, /var) only —
never touches /usr. Drives the management tasks below.

- playbooks/provision.yml
```

### Commit 15
```
feat(provision): manage domains, mailboxes, and aliases

Idempotent add/remove of virtual domains, mailboxes, and aliases against
Dovecot/Postfix maps in /etc and mail storage in /var.

- roles/postfix/tasks/domains.yml, aliases.yml
- roles/dovecot/tasks/mailboxes.yml
- defaults documenting the mailstack_domains / mailstack_mailboxes shapes
```

### Commit 16
```
feat(provision): generate and rotate DKIM keys and emit DNS records

Create per-domain DKIM keypairs with community.crypto, install them for
Rspamd signing, and render the TXT/SPF/DMARC records to publish.

- roles/rspamd/tasks/dkim.yml
- roles/rspamd/templates/dns_records.txt.j2
```

### Commit 17
```
feat(provision): install and renew TLS certificates

Place TLS material for Postfix and Dovecot and reload services on change,
supporting both supplied certs and ACME-issued material.

- roles/postfix/tasks/tls.yml
- roles/dovecot/tasks/tls.yml
```

---

## Phase 7 — Verification and docs

### Commit 18
```
test(molecule): add container-based smoke scenario

Stand the roles up in a Fedora container and assert services start,
ports listen, and a test message flows end-to-end through the milter.

- molecule/default/molecule.yml
- molecule/default/converge.yml
- molecule/default/verify.yml
```

### Commit 19
```
ci(github): run molecule on pull requests

Extend CI to execute the molecule smoke scenario alongside lint.

- .github/workflows/molecule.yml
```

### Commit 20
```
docs(collection): document roles, variables, and operations model

Per-role READMEs plus a top-level operations guide covering the day-1 /
day-2 split and the DNS records operators must publish.

- roles/*/README.md
- docs/operations.md
```

---

## Notes

- **Ordering rationale.** Backend (Valkey) precedes its consumer (Rspamd);
  the milter (Rspamd) precedes the MTA (Postfix); delivery (Dovecot) follows;
  Fail2ban is last so its filters match real log output.
- **bootc discipline.** Build playbook = build-time only (installs packages,
  enables units, bakes base config). Provision playbook = runtime, `/etc` and
  `/var` only. No package installs at runtime.
- **Squash-friendly.** Each commit is independently buildable; if you prefer
  fewer commits, Phases 2–4 can each collapse into one `feat` commit.
