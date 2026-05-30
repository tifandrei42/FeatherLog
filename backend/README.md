# FeatherLog Sync Backend (optional)

This directory contains an **optional** self-hostable sync server. The app works fully without it — this exists for users who want multi-device sync and for demonstrating infrastructure/ops skills.

## What it is

[PocketBase](https://pocketbase.io/) — a single Go binary giving you a database, auth, REST API, and realtime subscriptions. Chosen because it's open-source, runs anywhere, and has near-zero operational overhead.

## Run locally

```bash
docker compose up -d
# Admin UI: http://localhost:8090/_/
# Health:   http://localhost:8090/api/health
```

Data persists in `./pb_data` (gitignored).

## Production deployment (DevOps showcase)

The intended portfolio story for this backend:

1. **Containerized** — see `Dockerfile` (multi-stage-friendly, pinned version, healthcheck).
2. **Infrastructure-as-Code** — provision a small VPS with **Terraform**, configure it with **Ansible** (install Docker, copy compose, set up a reverse proxy).
3. **TLS** — front it with **Caddy** or **Traefik** for automatic HTTPS.
4. **Deploy on release** — a GitHub Actions job that SSHes in (or uses a registry) to roll out the new container on a tagged release.
5. **Observability** — expose metrics, scrape with **Prometheus**, dashboard in **Grafana**; alert on the healthcheck.
6. **Backups** — a scheduled job that snapshots `pb_data` to object storage.

> These pieces are intentionally listed as a roadmap. Implement them incrementally — even steps 1–3 alone make a credible ops demonstration.

## Privacy note

If you run sync, weight data leaves the device and lands on your server. Document this clearly for users, enable TLS, and keep the server patched. The app's default remains local-only.
