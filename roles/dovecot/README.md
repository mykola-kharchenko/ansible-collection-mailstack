# dovecot

IMAP/POP3 (with implicit-TLS variants), the LMTP delivery endpoint and SASL auth
socket for Postfix, and Pigeonhole Sieve. Mailboxes are Maildir under
`/var/mail/vhosts/%d/%n` owned by a single `vmail` system user; virtual
credentials come from a passwd-file passdb.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_dovecot_mail_root` | `/var/mail/vhosts` | Mailbox storage root |
| `mailstack_dovecot_userdb_file` | `/etc/dovecot/users` | passwd-file passdb |
| `mailstack_dovecot_password_scheme` | `ARGON2ID` | Password hashing scheme |
| `mailstack_dovecot_tls_cert` / `_key` | `/etc/pki/tls/...` | Server TLS paths |
| `mailstack_dovecot_firewall_ports` | 143/993/110/995 | Ports opened in firewalld |

## Day-2

- `tasks_from: mailboxes.yml` — credentials + Maildir storage from
  `mailstack_mailboxes` (pre-hash with `doveadm pw -s ARGON2ID`).
- `tasks_from: tls.yml` — install `mailstack_dovecot_tls_cert_content` / `_key_content`.
