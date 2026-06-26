# repos

The only distribution-divergent role. Enables the repositories the rest of the
stack installs from. On **Fedora** everything is in the base repos, so this is
effectively a no-op (beyond `dnf-plugins-core`). On **RHEL** it enables
CodeReady Builder, installs EPEL, and adds the upstream Rspamd stable repo.

## Key variables

| Variable | Default | Purpose |
|---|---|---|
| `mailstack_enable_crb` | `true` | Enable CodeReady Builder (RHEL) |
| `mailstack_enable_epel` | `true` | Install EPEL release (RHEL) |
| `mailstack_enable_rspamd_repo` | `true` | Add upstream Rspamd repo (RHEL) |
| `mailstack_crb_repo_id` | RHEL CRB id | Override for clones (e.g. `crb`) |
| `mailstack_rspamd_repo_baseurl` | rspamd.com stable | Rspamd RPM repo URL |

## Example

```yaml
- hosts: all
  roles:
    - mykola_kharchenko.mailstack.repos
```
