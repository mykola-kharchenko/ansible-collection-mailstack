# Operations guide

This collection separates **day-1 (build-time)** from **day-2 (runtime)**,
matching the immutable `/usr` + persistent `/etc`/`/var` model of bootc.

| | Day-1 (build) | Day-2 (runtime) |
|---|---|---|
| Playbook | `build.yml` | `provision.yml` |
| Where | `Containerfile` / `podman build` | running host |
| Touches | packages, base config, enabled units | `/etc`, `/var` only |
| `mailstack_start_services` | `false` (enable only) | `true` |

Day-1 is covered in [building.md](building.md). This document covers day-2.

## Inventory

```ini
[mailservers]
mail.example.com
```

## Adding a domain

```yaml
mailstack_domains:
  - example.com
```

Run `provision.yml`. This renders the Postfix virtual maps and (DKIM step)
generates a signing key for the domain.

## Adding a mailbox

Pre-hash the password — entries must be idempotent:

```bash
doveadm pw -s ARGON2ID -p 'the-password'
```

```yaml
mailstack_mailboxes:
  - user: alice@example.com
    password_hash: "{ARGON2ID}$argon2id$v=19$..."
```

`provision.yml` writes the credential to `/etc/dovecot/users`, provisions the
Maildir, and adds the address to Postfix's recipient map.

## Aliases

```yaml
mailstack_aliases:
  - source: info@example.com
    destination: alice@example.com
```

## DKIM keys and DNS

The DKIM step generates a keypair per domain under
`/var/lib/rspamd/dkim/<domain>.<selector>.key` and writes the records to publish
to `/var/lib/rspamd/dkim/dns_records.txt` — DKIM, plus SPF and DMARC
suggestions. Publish them in each domain's zone.

**Rotation:** bump `mailstack_rspamd_dkim_selector` (e.g. `default` → `2026a`),
re-run `provision.yml` to generate a fresh key under the new selector, publish
the new record, then retire the old one once propagated.

## TLS certificates

Provide PEM contents to install/renew:

```yaml
mailstack_postfix_tls_cert_content: "{{ lookup('file', 'mail.crt') }}"
mailstack_postfix_tls_key_content:  "{{ lookup('file', 'mail.key') }}"
mailstack_dovecot_tls_cert_content: "{{ lookup('file', 'mail.crt') }}"
mailstack_dovecot_tls_key_content:  "{{ lookup('file', 'mail.key') }}"
```

Leave them empty to manage the files out of band (e.g. a certbot deploy hook);
the TLS tasks become a no-op and the services keep their existing certs.
