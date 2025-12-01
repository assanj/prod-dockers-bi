# Останавливаем
cd ~/prod-dockers-bi/prod-superset
docker compose -f docker-compose-non-dev-clickhouse.yml down

# Запускаем с обновленной конфигурацией
docker compose -f docker-compose-non-dev-clickhouse.yml up -d



# Проверим логи последнего запуска superset-init
docker logs superset_init

# Проверка всех контейнеров
docker compose -f docker-compose-non-dev-clickhouse.yml ps

# Проверка БД
docker exec superset_db psql -U superset -d superset -c "\l"

# Логи инициализации
docker logs superset-init

# Логи приложения
docker logs superset-app

# Посмотрим сеть bi-network
docker network inspect bi-network
docker network ls
docker network ls | grep bi-network
docker network inspect superset-prod_default

# удалить сеть
docker network rm superset-prod_default

# Проверим, доступен ли prod-postgres в сети
docker run --rm --network bi-network appropriate/curl curl -v prod-postgres:5432

# Или попробуем подключиться через psql
docker run --rm --network bi-network postgres:16 psql -h prod-postgres -p 5432 -U postgres -c "SELECT 1;"





Вот 3 полезные команды для работы с БД PostgreSQL:

## 1. **Проверка пользователей Superset в БД**
```bash
docker exec superset_db psql -U superset -d superset -c "SELECT username, email, first_name, last_name FROM ab_user;"
```
*Показывает всех зарегистрированных пользователей Superset*

## 2. **Проверка дашбордов и чартов**
```bash
docker exec superset_db psql -U superset -d superset -c "SELECT dashboard_title, slug FROM dashboards LIMIT 5;"
```
*Показывает созданные дашборды*

## 3. **Размер БД и таблиц**
```bash
docker exec superset_db psql -U superset -d superset -c "
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname NOT IN ('information_schema', 'pg_catalog') 
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC 
LIMIT 10;"
```
*Показывает самые большие таблицы в БД*

Эти команды помогут мониторить состояние Superset и его данных в PostgreSQL.
