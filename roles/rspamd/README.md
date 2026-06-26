# rspamd

The single filtering daemon: spam scoring, DKIM signing, greylisting, ARC/DMARC
and (via the clamav role) antivirus. The proxy worker runs in self-scan **milter
mode** — the socket Postfix hands mail to. Bayes, greylist and ratelimits use the
Valkey backend.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_rspamd_redis_servers` | `127.0.0.1:6379` | Valkey backend |
| `mailstack_rspamd_milter_bind` | `localhost:11332` | Milter socket for Postfix |
| `mailstack_rspamd_controller_password` | `""` | Hashed controller password (`rspamadm pw`) |
| `mailstack_rspamd_dkim_path` | `/var/lib/rspamd/dkim` | DKIM key location |
| `mailstack_rspamd_dkim_selector` | `default` | DKIM selector |

## Day-2

`tasks_from: dkim.yml` generates per-domain DKIM keys from `mailstack_domains`
and writes the DNS records to publish (`dns_records.txt`).
