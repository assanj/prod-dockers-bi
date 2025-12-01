# Production BI Stack - Docker Compose

## Architecture Overview

### Directory Structure

~/prod-dockers-bi/
├── .env # Common environment variables
├── ARCHITECTURE.txt # Architecture documentation
├── prod-postgres/ # Shared PostgreSQL
│ ├── docker-compose.yml
│ ├── help-postgres.md
│ └── .env-local
├── prod-superset/ # Apache Superset
│ ├── docker-compose-non-dev-clickhouse.yml
│ ├── docker/
│ │ └── docker-init-smart.sh
│ ├── help-superset.md
│ ├── git-help.txt
│ ├── postgres_help.txt
│ └── .gitignore
├── prod-metabase/ # Metabase
│ ├── docker-compose.yml
│ ├── docker-metabase-init.sh
│ ├── prod-matabase-plan.txt
│ └── help-metabase.md
└── tabix/ # ClickHouse Tabix Web Client
├── docker-compose.yml
├── docker-compose-tabix.yml
├── .env
└── help-tabix.md
text


## Services

### 1. PostgreSQL (prod-postgres)
- Container: prod-postgres
- Network: prod-postgres_bi-network (external: false)
- Volume: postgres_data (external: false, name: ${POSTGRES_VOLUME_NAME:-postgres_data})
- Port: 5432
- Credentials: from .env (POSTGRES_ADMIN_USER/PASSWORD)
- Authentication: md5 (POSTGRES_HOST_AUTH_METHOD)

### 2. Superset (prod-superset)
- Main container: superset_app (port 8088)
- Init container: superset_init (command: ["/app/docker/docker-init-smart.sh"])
- Worker: superset-worker, superset-worker-beat
- Redis: superset_cache
- Fallback DB: superset_db (only with --profile fallback-db)

#### docker-init-smart.sh logic:
1. Checks availability of prod-postgres:5432
2. Tries to connect as superset:superset
3. If fails → connects as postgres:postgres
4. Creates superset user and DB if they don't exist
5. Uses shared DB or local fallback
6. Runs superset db upgrade, create-admin, init

### 3. Metabase (prod-metabase)
- Main container: metabase (port 3000)
- Init container: metabase_init (command: ["sh", "/docker-metabase-init.sh"])
- Dependency: metabase depends on metabase-init (service_completed_successfully)

#### docker-metabase-init.sh logic:
1. Checks availability of prod-postgres:5432
2. Checks existence of metabase user and DB via psql
3. If they don't exist → creates them
4. Similar logic to Superset but for Metabase

### 4. Tabix (tabix)
- Container: tabix (port 8181)
- Image: spoonest/clickhouse-tabix-web-client:latest
- Web interface for ClickHouse

## Network
- Name: prod-postgres_bi-network
- Type: bridge
- Creation: automatic when starting PostgreSQL (external: false in PostgreSQL compose)
- Usage: all services connect to the same network
- External usage: external: true in Superset and Metabase compose files

## Environment Variables (.env)
POSTGRES_HOST=prod-postgres
POSTGRES_PORT=5432
POSTGRES_ADMIN_USER=postgres
POSTGRES_ADMIN_PASSWORD=postgres123
POSTGRES_HOST_AUTH_METHOD=md5

SUPERSET_DATABASE_USER=superset
SUPERSET_DATABASE_PASSWORD=superset
SUPERSET_DATABASE_NAME=superset

METABASE_DATABASE_USER=metabase
METABASE_DATABASE_PASSWORD=metabase
METABASE_DATABASE_NAME=metabase

## Startup Order
1. PostgreSQL: `docker compose up -d` (creates network)
2. Superset: `docker compose -f docker-compose-non-dev-clickhouse.yml up -d`
3. Metabase: `docker compose up -d`
4. Tabix (optional): `docker compose up -d`

## Access URLs
- **Superset**: http://localhost:8088 (admin/admin)
- **Metabase**: http://localhost:3000
- **Tabix**: http://localhost:8181

## Important Principles
- DO NOT simplify code without explicit user request
- Init scripts create users/DB only if they don't exist
- All scripts are saved in full without abbreviations
- external: false for networks/volumes in main project (PostgreSQL)
- external: true for networks in dependent projects (Superset, Metabase)
- One .env file for all services with default values
- Variable substitution in docker-compose: ${VAR_NAME:-default}
- Dependencies via depends_on with condition: service_completed_successfully

## Help Files
Each service directory contains help files (help-*.md) with specific commands and instructions.

## Notes
- Default passwords should be changed in production
- PostgreSQL data is persisted in Docker volume
- Services use health checks for proper startup order
- Fallback databases ensure availability even if shared PostgreSQL is unavailable
