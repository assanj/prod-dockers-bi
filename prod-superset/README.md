```txt
SUPERSET PRODUCTION SETUP WITH CLICKHOUSE SUPPORT
==================================================

PROJECT OVERVIEW
----------------
Complete Apache Superset deployment with Docker Compose, optimized for ClickHouse database connectivity. Successfully deployed production-ready Apache Superset with full container orchestration.

ARCHITECTURE COMPONENTS
-----------------------
- Superset Application - Web interface and API (Gunicorn)
- PostgreSQL 16 - Metadata database
- Redis 7 - Caching and Celery broker
- Celery Worker - Background task processor
- Celery Beat - Scheduled task manager

CUSTOM DOCKER IMAGES
--------------------
Built and published optimized Superset images with ClickHouse support:

Docker Hub: https://hub.docker.com/repositories/assanj

Available Images:
- assanj/superset-app:latest2025Nov
- assanj/superset-worker:latest2025Nov
- assanj/superset-worker-beat:latest2025Nov

CLICKHOUSE CONFIGURATION
------------------------
This setup uses the clickhouse-connect driver, the official library recommended by Apache Superset for connecting to ClickHouse.

Connection String:
clickhousedb://{username}:{password}@{hostname}:{port}/{database}

Official Documentation:
https://superset.apache.org/docs/configuration/databases/#clickhouse

QUICK DEPLOYMENT
----------------

1. CLONE & SETUP
git clone https://github.com/assanj/docker-compose-non-dev-clickhouse.git
cd docker-compose-non-dev-clickhouse

2. CONFIGURE ENVIRONMENT
nano docker/.env

Copy and paste this configuration:

# POSTGRESQL DATABASE CONFIGURATION
POSTGRES_PASSWORD=superset
DATABASE_DB=superset
DATABASE_USER=superset
DATABASE_PASSWORD=superset
DATABASE_HOST=db
DATABASE_PORT=5432

# REDIS CACHE CONFIGURATION
REDIS_PASSWORD=superset
REDIS_HOST=redis

# SUPERSET SECURITY CONFIGURATION
SECRET_KEY=change-this-to-very-secure-random-key-123

# APPLICATION SETTINGS
SUPERSET_LOAD_EXAMPLES=no

Save the file:
- Press Ctrl+X
- Press Y to confirm
- Press Enter to save

3. DEPLOY
docker compose -f docker-compose-non-dev-clickhouse.yml up -d

4. ACCESS
URL: http://localhost:8088
Login: admin / admin

PASSWORD PRIORITY
-----------------
- If .env file exists: PASSWORDS FROM .env FILE WILL BE USED
- If .env file missing: PASSWORDS FROM docker-compose.yml WILL BE USED
- .env file OVERRIDES docker-compose.yml settings

TECHNICAL IMPLEMENTATION
------------------------
- Multi-stage initialization process
- Health checks and dependency management
- Persistent volumes for data storage
- Isolated bridge network
- Custom SECRET_KEY enforcement
- Gunicorn with multiple workers
- Celery for asynchronous processing
- Redis for caching and message brokering

VOLUME STRATEGY
---------------
- superset_home - Superset configs and files
- db_home - PostgreSQL data persistence
- redis - Redis data persistence
- ./docker - Local script overrides

USAGE NOTES
-----------
- Default admin credentials should be changed after first login
- ClickHouse databases can be added via Superset UI
- All configurations are environment-driven
- Docker volumes ensure data persistence

MAINTENANCE
-----------
- Logs: docker compose logs [service]
- Restart: docker compose restart [service]
- Updates: Pull new images and recompose
- Backup: Volume data and database dumps

NETWORK ACCESS
--------------
- Primary: http://localhost:8088
- Alternative: http://[machine-ip]:8088

STATUS: PRODUCTION READY

COMPLETE DOCKER MAINTENANCE GUIDE
==================================

DOCKER MANAGEMENT
-----------------

CONTAINER OPERATIONS
- View all containers: docker ps -a
- View running containers: docker ps
- Start all services: docker compose -f docker-compose-non-dev-clickhouse.yml up -d
- Stop all services: docker compose -f docker-compose-non-dev-clickhouse.yml down
- Restart specific service: docker compose -f docker-compose-non-dev-clickhouse.yml restart superset
- Stop specific container: docker stop superset_app
- Start specific container: docker start superset_app
- Remove specific container: docker rm superset_app
- View container resources: docker stats

IMAGE MANAGEMENT
- List all images: docker images
- Pull latest images: docker compose -f docker-compose-non-dev-clickhouse.yml pull
- Remove unused images: docker image prune
- Remove specific image: docker rmi image_name:tag

VOLUME MANAGEMENT
- List volumes: docker volume ls
- Inspect volume: docker volume inspect superset-prod_superset_home
- Backup volume: docker run --rm -v superset-prod_superset_home:/source -v $(pwd):/backup alpine tar czf /backup/superset_home_backup.tar.gz -C /source .
- Restore volume: docker run --rm -v superset-prod_superset_home:/target -v $(pwd):/backup alpine tar xzf /backup/superset_home_backup.tar.gz -C /target
- Remove volume: docker volume rm volume_name

NETWORK MANAGEMENT
- List networks: docker network ls
- Inspect network: docker network inspect superset-prod_default

DATABASE MANAGEMENT
-------------------

POSTGRESQL OPERATIONS
- Connect to PostgreSQL: docker exec -it superset_db psql -U superset -d superset
- Backup database: docker exec superset_db pg_dump -U superset superset > superset_backup.sql
- Restore database: docker exec -i superset_db psql -U superset superset < superset_backup.sql
- Backup with custom format: docker exec superset_db pg_dump -U superset -Fc superset > superset_backup.dump
- Restore custom format: docker exec -i superset_db pg_restore -U superset -d superset -Fc < superset_backup.dump

REDIS OPERATIONS
- Connect to Redis: docker exec -it superset_cache redis-cli
- Monitor Redis: docker exec -it superset_cache redis-cli monitor
- Redis info: docker exec -it superset_cache redis-cli info

LOGS AND MONITORING
-------------------

VIEW LOGS
- All services logs: docker compose -f docker-compose-non-dev-clickhouse.yml logs
- Specific service logs: docker compose -f docker-compose-non-dev-clickhouse.yml logs superset
- Follow logs (real-time): docker compose -f docker-compose-non-dev-clickhouse.yml logs -f superset
- Last N lines: docker compose -f docker-compose-non-dev-clickhouse.yml logs --tail=100 superset
- Logs with timestamps: docker compose -f docker-compose-non-dev-clickhouse.yml logs -t

CONTAINER INSPECTION
- Inspect container: docker inspect superset_app
- View container processes: docker top superset_app
- View container resources: docker stats superset_app
- Execute command in container: docker exec -it superset_app bash

DEBUGGING AND TROUBLESHOOTING
------------------------------

COMMON ISSUES
- Check container status: docker compose -f docker-compose-non-dev-clickhouse.yml ps
- Check health status: docker inspect --format='{{.State.Health.Status}}' superset_db
- View environment variables: docker exec superset_app env
- Check disk space: docker exec superset_app df -h
- Check memory usage: docker exec superset_app free -h

NETWORK TROUBLESHOOTING
- Test connectivity: docker exec superset_app ping db
- Check port mapping: docker port superset_app
- Network diagnostics: docker exec superset_app netstat -tulpn

MIGRATION AND TRANSFER
----------------------

FULL PROJECT MIGRATION
1. Backup all data:
docker compose -f docker-compose-non-dev-clickhouse.yml down
docker run --rm -v superset-prod_superset_home:/source -v $(pwd):/backup alpine tar czf /backup/superset_home.tar.gz -C /source .
docker run --rm -v superset-prod_db_home:/source -v $(pwd):/backup alpine tar czf /backup/db_home.tar.gz -C /source .
docker exec superset_db pg_dump -U superset superset > superset_db.sql

2. Transfer files to new machine:
scp *.tar.gz *.sql user@new-machine:/path/

3. On new machine:
git clone https://github.com/assanj/docker-compose-non-dev-clickhouse.git
cd docker-compose-non-dev-clickhouse
docker compose -f docker-compose-non-dev-clickhouse.yml up -d db
docker exec -i superset_db psql -U superset superset < superset_db.sql
docker compose -f docker-compose-non-dev-clickhouse.yml down
docker volume create superset-prod_superset_home
docker volume create superset-prod_db_home
docker run --rm -v superset-prod_superset_home:/target -v $(pwd):/backup alpine tar xzf /backup/superset_home.tar.gz -C /target
docker run --rm -v superset-prod_db_home:/target -v $(pwd):/backup alpine tar xzf /backup/db_home.tar.gz -C /target
docker compose -f docker-compose-non-dev-clickhouse.yml up -d

PARTIAL MIGRATION
- Export Superset metadata: docker exec superset_db pg_dump -U superset -n public superset > superset_metadata.sql
- Export user data: docker exec superset_db pg_dump -U superset -t ab_user -t ab_role -t ab_permission superset > users_data.sql

GIT MANAGEMENT
--------------

BASIC GIT OPERATIONS
- Check status: git status
- View changes: git diff
- Add files: git add .
- Commit changes: git commit -m "Description of changes"
- Push to repository: git push origin main
- Pull updates: git pull origin main

BRANCH MANAGEMENT
- View branches: git branch -a
- Create new branch: git checkout -b feature-branch
- Switch branch: git checkout main
- Merge branches: git merge feature-branch
- Delete branch: git branch -d feature-branch

TROUBLESHOOTING GIT
- View git history: git log --oneline
- Reset to previous commit: git reset --hard HEAD~1
- View remote repository: git remote -v
- Update remote URL: git remote set-url origin https://github.com/assanj/docker-compose-non-dev-clickhouse.git

PERFORMANCE OPTIMIZATION
------------------------

DATABASE OPTIMIZATION
- PostgreSQL performance: docker exec superset_db psql -U superset -d superset -c "SELECT * FROM pg_stat_activity;"
- Redis memory info: docker exec superset_cache redis-cli info memory

CONTAINER OPTIMIZATION
- Monitor resource usage: docker system df
- Cleanup system: docker system prune

SECURITY
--------

SECURITY PRACTICES
- Regular updates:
docker compose -f docker-compose-non-dev-clickhouse.yml pull
docker compose -f docker-compose-non-dev-clickhouse.yml up -d

- Change default passwords:
Edit docker/.env file
SECRET_KEY=your-new-secure-key
POSTGRES_PASSWORD=your-new-password

- Backup security:
tar czf backup_$(date +%Y%m%d).tar.gz *.tar.gz *.sql
rm *.tar.gz *.sql

AUTOMATION SCRIPTS
------------------

BACKUP SCRIPT (backup.sh)
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker exec superset_db pg_dump -U superset superset > superset_db_$DATE.sql
docker compose -f docker-compose-non-dev-clickhouse.yml down
docker run --rm -v superset-prod_superset_home:/source -v $(pwd):/backup alpine tar czf /backup/superset_home_$DATE.tar.gz -C /source .
docker compose -f docker-compose-non-dev-clickhouse.yml up -d
echo "Backup completed: superset_db_$DATE.sql, superset_home_$DATE.tar.gz"

RESTORE SCRIPT (restore.sh)
#!/bin/bash
echo "Restoring from backup..."
docker compose -f docker-compose-non-dev-clickhouse.yml down
docker run --rm -v superset-prod_superset_home:/target -v $(pwd):/backup alpine tar xzf /backup/superset_home_$1.tar.gz -C /target
docker compose -f docker-compose-non-dev-clickhouse.yml up -d db
docker exec -i superset_db psql -U superset superset < $2
docker compose -f docker-compose-non-dev-clickhouse.yml up -d
echo "Restore completed"

EMERGENCY PROCEDURES
--------------------

SYSTEM CRASH RECOVERY
If containers won't start:
docker compose -f docker-compose-non-dev-clickhouse.yml down
docker system prune -f
docker volume prune -f
docker compose -f docker-compose-non-dev-clickhouse.yml up -d

DATABASE CORRUPTION
Reset database (WARNING: data loss):
docker compose -f docker-compose-non-dev-clickhouse.yml down
docker volume rm superset-prod_db_home
docker compose -f docker-compose-non-dev-clickhouse.yml up -d db
Restore from backup

NETWORK ISSUES
Reset Docker network:
docker network rm superset-prod_default
docker compose -f docker-compose-non-dev-clickhouse.yml up -d

MONITORING AND ALERTS
---------------------

HEALTH CHECKS
#!/bin/bash
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8088/health)
if [ $HTTP_STATUS -ne 200 ]; then
    echo "Superset is down! Status: $HTTP_STATUS"
fi

LOG MONITORING
- Monitor for errors: docker compose -f docker-compose-non-dev-clickhouse.yml logs superset | grep -i error
- Monitor for patterns: docker compose -f docker-compose-non-dev-clickhouse.yml logs -f superset | grep --line-buffered "ERROR\|WARNING"

DOCKER COMMANDS QUICK REFERENCE
--------------------------------
- Remove stopped containers: docker container prune
- Remove unused networks: docker network prune
- Remove unused images: docker image prune -a
- Remove unused volumes: docker volume prune
- System-wide cleanup: docker system prune -a --volumes
- View disk usage: docker system df
- Detailed disk usage: docker system df -v
```



