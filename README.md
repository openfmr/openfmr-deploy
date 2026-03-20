# OpenFMR Deploy

> **Master orchestration repository** for the [OpenFMR Health Information Exchange](https://github.com/YourOrg).
>
> Clone this repo, run the install script, and bring the entire HIE up with a single command.

---

## Repository Map

After running `install.sh`, the directory will look like this:

```
openfmr-deploy/
├── .env.global                   ← Shared credentials & config
├── README.md
├── scripts/
│   ├── install.sh                ← Clone all sub-repos
│   ├── start.sh                  ← Bring everything up
│   └── stop.sh                   ← Tear everything down
├── offline-tools/
│   └── save-images.sh            ← Export Docker images for USB
│
├── openfmr-core/                 ← (cloned) Databases, OpenHIM, Keycloak
├── openfmr-module-cr/            ← (cloned) Client Registry
├── openfmr-module-hfr/           ← (cloned) Health Facility Registry
├── openfmr-module-ts/            ← (cloned) Terminology Service
├── openfmr-module-shr/           ← (cloned) Shared Health Record
├── openfmr-module-lmis/          ← (cloned) Logistics Management
├── openfmr-admin-ui/             ← (cloned) Data Steward Admin UI
├── openfmr-clinical-ui/          ← (cloned) Clinical (Doctor) UI
└── openfmr-operations-ui/        ← (cloned) Operations / Billing UI
```

---

## Prerequisites

| Tool             | Minimum Version |
|------------------|-----------------|
| Docker           | 20.10+          |
| Docker Compose   | 2.x (V2 plugin)|
| Git              | 2.30+           |
| Bash             | 4.0+            |

---

## Quick Start

### 1 · Install (clone all repositories)

```bash
bash scripts/install.sh
```

> The script is **idempotent** — existing directories are skipped.

### 2 · Configure credentials

Edit `.env.global` and replace every `Change_Me_*` placeholder with strong passwords before deploying to any real environment.

### 3 · Start the HIE

```bash
bash scripts/start.sh
```

Services start in dependency order:

1. **External network** `openfmr_global_net` is created.
2. **openfmr-core** (PostgreSQL, MongoDB, OpenHIM, Keycloak, HAPI FHIR) boots and settles.
3. **Registry modules** (CR → HFR → TS → SHR → LMIS) are built and started.
4. **UI front-ends** (Admin, Clinical, Operations) are built and started.

Once complete, you'll see a summary of URLs:

| Service          | URL                          |
|------------------|------------------------------|
| OpenHIM Console  | http://localhost:9000        |
| OpenHIM API      | https://localhost:8085       |
| Keycloak         | https://localhost:8443       |
| HAPI FHIR        | http://localhost:8080        |

### 4 · Stop the HIE

```bash
# Stop all containers (keep network)
bash scripts/stop.sh

# Stop all containers AND remove the shared network
bash scripts/stop.sh --remove-net
```

---

## Offline / Air-gapped Deployment

For clinics without internet access:

```bash
# On a machine WITH internet
bash offline-tools/save-images.sh

# Copy the offline-images/ folder to a USB drive, then on the target machine:
for f in offline-images/*.tar; do docker load -i "$f"; done
```

---

## Environment Variables

All shared configuration lives in **`.env.global`** at the project root. Each module's `docker-compose.yml` is invoked with `--env-file ../.env.global` so that credentials are consistent across the stack.

Key variable groups:

- **PostgreSQL** — `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`
- **OpenHIM** — `OPENHIM_ROOT_USER`, `OPENHIM_ROOT_PASSWORD`, ports
- **Keycloak** — `KEYCLOAK_ADMIN`, `KEYCLOAK_ADMIN_PASSWORD`, ports
- **Per-module DB names** — `CR_DB_NAME`, `HFR_DB_NAME`, `TS_DB_NAME`, `SHR_DB_NAME`, `LMIS_DB_NAME`

---

## Customisation

| What                    | Where to change                              |
|-------------------------|----------------------------------------------|
| GitHub org / URLs       | `scripts/install.sh` → `REPOS` array        |
| Core wait time          | `CORE_WAIT_SECONDS` env var (default 30s)    |
| Docker images to export | `offline-tools/save-images.sh` → `IMAGES`   |
| Network name            | `.env.global` → `OPENFMR_NETWORK`           |

---

## License

This deployment scaffold is provided under the same license as the parent OpenFMR project.
