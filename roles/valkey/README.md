# valkey

Installs and configures Valkey as Rspamd's backend for statistics, greylisting
and ratelimits. Binds loopback only, `noeviction` policy so learned Bayes tokens
are never dropped, RDB snapshots on so state survives reboot.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_valkey_bind` | `127.0.0.1` | Listen address |
| `mailstack_valkey_port` | `6379` | Listen port |
| `mailstack_valkey_maxmemory` | `256mb` | Memory cap |
| `mailstack_valkey_maxmemory_policy` | `noeviction` | Eviction policy |
| `mailstack_valkey_save` | `true` | RDB snapshots |
| `mailstack_start_services` | `true` | Start (vs only enable) the unit |
