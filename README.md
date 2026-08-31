# ShopLite DevOps Platform

A production-grade DevOps platform built end-to-end: Python API → Git →
Jenkins CI/CD → Docker → Terraform (AWS) → Kubernetes → Monitoring.

This repo is being built in public, week by week, as a hands-on portfolio
project. See [docs/architecture.md](docs/architecture.md) *(coming soon)*
for the full design.

## Status
- [x] Week 1 — Order API (FastAPI) + unit tests
- [ ] Week 2 — Dockerize
- [ ] Week 3 — Jenkins CI pipeline
- [ ] Week 4 — Terraform basics + remote state
- [ ] Week 5 — Terraform provisions the cluster
- [ ] Week 6 — Kubernetes deployment
- [ ] Week 7 — Observability (Prometheus/Grafana, logging)
- [ ] Week 8 — Security scanning + documentation polish

## Run it locally

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r app/requirements-dev.txt
uvicorn app.main:app --reload
```

Visit `http://localhost:8000/docs` for interactive API docs (FastAPI's
built-in Swagger UI).

## Run the tests

```bash
pytest -v
```

## API Endpoints

| Method | Path | Description |
|---|---|---|
| GET | `/health` | Liveness/readiness check (used by K8s probes later) |
| POST | `/orders` | Create an order |
| GET | `/orders/{order_id}` | Get a single order |
| GET | `/orders` | List all orders |

running it from jenkins automatically by polling the git commit done automatically every 5 mins.