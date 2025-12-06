#!/bin/bash
set -e

echo "=== METABASE DATABASE INITIALIZATION ==="

# Параметры
PG_HOST="localhost"
PG_PORT="${POSTGRES_PORT:-5432}"
PG_ADMIN_USER="${POSTGRES_ADMIN_USER:-postgres}"
PG_ADMIN_PASS="${POSTGRES_ADMIN_PASSWORD:-postgres}"
MB_USER="${METABASE_DATABASE_USER:-metabase}"
MB_PASS="${METABASE_DATABASE_PASSWORD:-metabase}"
MB_DB="${METABASE_DATABASE_NAME:-metabase}"

echo "Конфигурация:"
echo "  PostgreSQL: $PG_HOST:$PG_PORT"
echo "  Админ: $PG_ADMIN_USER"
echo "  Пользователь Metabase: $MB_USER"
echo "  БД Metabase: $MB_DB"

# Проверка доступности PostgreSQL
echo "Проверка подключения к PostgreSQL..."
export PGPASSWORD="$PG_ADMIN_PASS"

if psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" -d postgres -c "SELECT 1" >/dev/null 2>&1; then
  echo "✓ PostgreSQL доступен"
else
  echo "✗ Не удалось подключиться к PostgreSQL"
  echo "Проверьте пароль для пользователя '$PG_ADMIN_USER' в файле .env"
  exit 1
fi

# Создание пользователя Metabase
echo "Проверка пользователя $MB_USER..."
USER_EXISTS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" -d postgres -t -c \
  "SELECT 1 FROM pg_roles WHERE rolname='$MB_USER';" 2>/dev/null | tr -d '[:space:]')

if [ "$USER_EXISTS" != "1" ]; then
  echo "Создание пользователя: $MB_USER"
  psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" -d postgres -c \
    "CREATE USER \"$MB_USER\" WITH PASSWORD '$MB_PASS';" 2>/dev/null && \
    echo "✓ Пользователь создан" || echo "⚠ Не удалось создать пользователя"
else
  echo "✓ Пользователь уже существует"
fi

# Создание БД Metabase
echo "Проверка БД $MB_DB..."
DB_EXISTS=$(psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" -d postgres -t -c \
  "SELECT 1 FROM pg_database WHERE datname='$MB_DB';" 2>/dev/null | tr -d '[:space:]')

if [ "$DB_EXISTS" != "1" ]; then
  echo "Создание БД: $MB_DB"
  psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_ADMIN_USER" -d postgres -c \
    "CREATE DATABASE \"$MB_DB\" OWNER \"$MB_USER\";" 2>/dev/null && \
    echo "✓ БД создана" || echo "⚠ Не удалось создать БД"
else
  echo "✓ БД уже существует"
fi

echo "=== ИНИЦИАЛИЗАЦИЯ ЗАВЕРШЕНА ==="
echo "Metabase будет использовать:"
echo "  Хост: $PG_HOST"
echo "  Порт: $PG_PORT"
echo "  БД: $MB_DB"
echo "  Пользователь: $MB_USER"
exit 0
