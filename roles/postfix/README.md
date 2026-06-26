# postfix

The MTA: inbound/outbound SMTP plus submission on 587 (STARTTLS) and 465
(implicit TLS). All mail passes through the Rspamd milter; local delivery is
virtual-only, handed to Dovecot over LMTP. Submission requires Dovecot SASL and
is restricted to authenticated relay.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_postfix_myhostname` | `mail.<domain>` | HELO name |
| `mailstack_postfix_milter` | `inet:localhost:11332` | Rspamd milter |
| `mailstack_postfix_virtual_transport` | `lmtp:unix:private/dovecot-lmtp` | Delivery |
| `mailstack_postfix_tls_cert` / `_key` | `/etc/pki/tls/...` | Server TLS paths |
| `mailstack_postfix_firewall_ports` | 25/465/587 | Ports opened in firewalld |

## Day-2

- `tasks_from: domains.yml` — render `virtual_domains` + `virtual_mailbox` from
  `mailstack_domains` / `mailstack_mailboxes`.
- `tasks_from: aliases.yml` — render `virtual_alias` from `mailstack_aliases`.
- `tasks_from: tls.yml` — install `mailstack_postfix_tls_cert_content` / `_key_content`.
