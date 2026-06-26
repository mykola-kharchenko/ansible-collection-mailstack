# fail2ban

Brute-force protection on SMTP and IMAP auth. Jails for `postfix`,
`postfix-sasl`, `dovecot` and `sieve` read the systemd journal and enforce bans
through firewalld, using the stock fail2ban filters.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_fail2ban_jails` | postfix, postfix-sasl, dovecot, sieve | Jails to enable |
| `mailstack_fail2ban_bantime` | `1h` | Ban duration |
| `mailstack_fail2ban_findtime` | `10m` | Failure window |
| `mailstack_fail2ban_maxretry` | `5` | Failures before ban |
| `mailstack_fail2ban_banaction` | `firewallcmd-rich-rules` | Enforcement action |
| `mailstack_fail2ban_ignoreip` | `127.0.0.1/8 ::1` | Never-ban list |
