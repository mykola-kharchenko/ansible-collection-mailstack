# clamav

Installs ClamAV and wires it to Rspamd's antivirus module over clamd's local
socket. The socket is group-owned by `_rspamd`; the required SELinux booleans
(`antivirus_can_scan_system`, `antivirus_use_jit`) are enabled. `freshclam`
seeds the signature database so clamd can start.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_clamav_instance` | `scan` | clamd@\<instance\> |
| `mailstack_clamav_socket` | `/run/clamd.scan/clamd.sock` | Local socket |
| `mailstack_clamav_action` | `reject` | Rspamd action on a virus hit |
| `mailstack_clamav_selinux_booleans` | see defaults | SELinux booleans to enable |

> Owns `/etc/rspamd/local.d/antivirus.conf` so the role is self-contained.
