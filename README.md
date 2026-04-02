# OpenFMR Deploy

> **Master orchestration repository** for the [OpenFMR Health Information Exchange](https://github.com/YourOrg).
>
> Clone this repo, run the install script, and bring the entire HIE up with a single command.
>
> **Works on Linux, macOS, and Windows.**

---

## Repository Map

After running the install script, the directory will look like this:

```
openfmr-deploy/
├── .env.global                   ← Shared credentials & config
├── README.md
├── setup.sh / setup.ps1          ← Root orchestrator
├── restart-all.sh / restart-all.ps1
├── scripts/
│   ├── install.sh / install.ps1  ← Clone all sub-repos
│   ├── start.sh / start.ps1     ← Bring everything up
│   ├── stop.sh / stop.ps1       ← Tear everything down
│   └── seed-practitioners.sh / seed-practitioners.ps1
├── offline-tools/
│   └── save-images.sh / save-images.ps1  ← Export Docker images for USB
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

### Linux / macOS

| Tool             | Minimum Version |
|------------------|-----------------|
| Docker           | 20.10+          |
| Docker Compose   | 2.x (V2 plugin)|
| Git              | 2.30+           |
| Bash             | 4.0+            |

### Windows

| Tool                  | Minimum Version     |
|-----------------------|---------------------|
| Docker Desktop        | 4.x+ (with WSL 2)  |
| Git for Windows       | 2.30+               |
| PowerShell            | 5.1+ (built-in) or 7+ |

> **Note:** The Windows PowerShell scripts use `docker compose` (V2 plugin syntax). Make sure Docker Desktop is running before executing any script.

---

## Quick Start

### 1 · Install (clone all repositories)

**Linux / macOS:**
```bash
bash scripts/install.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\install.ps1
```

> The script is **idempotent** — existing directories are skipped.

### 2 · Configure credentials

Edit `.env.global` and replace every `Change_Me_*` placeholder with strong passwords before deploying to any real environment.

### 3 · Start the HIE

**Linux / macOS:**
```bash
bash scripts/start.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\start.ps1
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

**Linux / macOS:**
```bash
# Stop all containers (keep network)
bash scripts/stop.sh

# Stop all containers AND remove the shared network
bash scripts/stop.sh --remove-net
```

**Windows (PowerShell):**
```powershell
# Stop all containers (keep network)
.\scripts\stop.ps1

# Stop all containers AND remove the shared network
.\scripts\stop.ps1 -RemoveNetwork
```

---

## One-Command Setup (Setup Wizard)

If this is a **first-time deployment**, run the root setup script instead. It will
detect whether `.env.global` exists and either launch the Setup Wizard or boot
the system automatically.

**Linux / macOS:**
```bash
bash setup.sh
```

**Windows (PowerShell):**
```powershell
.\setup.ps1
```

---

## Offline / Air-gapped Deployment

For clinics without internet access:

**Linux / macOS:**
```bash
# On a machine WITH internet
bash offline-tools/save-images.sh

# Copy the offline-images/ folder to a USB drive, then on the target machine:
for f in offline-images/*.tar; do docker load -i "$f"; done
```

**Windows (PowerShell):**
```powershell
# On a machine WITH internet
.\offline-tools\save-images.ps1

# Copy the offline-images\ folder to a USB drive, then on the target machine:
Get-ChildItem offline-images\*.tar | ForEach-Object { docker load -i $_.FullName }
```

---

## Seeding Test Practitioners

After the stack is running, seed sample Practitioner resources into HAPI FHIR:

**Linux / macOS:**
```bash
bash scripts/seed-practitioners.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\seed-practitioners.ps1
```

---

## Restart All Modules

Stop everything and restart in dependency order with stabilization waits:

**Linux / macOS:**
```bash
bash restart-all.sh
```

**Windows (PowerShell):**
```powershell
.\restart-all.ps1
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

| What                    | Where to change                                               |
|-------------------------|---------------------------------------------------------------|
| GitHub org / URLs       | `scripts/install.sh` (or `.ps1`) → `REPOS` / `$Repos` array |
| Core wait time          | `CORE_WAIT_SECONDS` env var (default 30s)                     |
| Docker images to export | `offline-tools/save-images.sh` (or `.ps1`) → `IMAGES`        |
| Network name            | `.env.global` → `OPENFMR_NETWORK`                            |

---

## License

This deployment scaffold is provided under the same license as the parent OpenFMR project.
