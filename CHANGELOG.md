# Changelog

All notable changes to this collection are documented here. The format is based
on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [0.1.0] - 2026-06-27

### Added

- Collection scaffold, lint/CI configuration, and GPL-3.0 license.
- `repos` role — distribution-divergent repository enablement (Fedora base
  repos; RHEL CodeReady Builder + EPEL + upstream Rspamd).
- Service roles: `valkey`, `rspamd`, `clamav`, `postfix`, `dovecot`, `fail2ban`,
  wired as native systemd units with a build-vs-runtime service split.
- firewalld port management for Postfix and Dovecot.
- Day-1 `build.yml` playbook and a `Containerfile` producing a bootc image.
- Day-2 `provision.yml` playbook: domains, mailboxes, aliases, DKIM key
  generation + DNS records, and TLS installation.
- Molecule smoke scenario and CI workflows (lint + molecule).
