#!/bin/bash
echo '=== METABASE DATABASE INITIALIZATION ==='

# Определяем какой PostgreSQL использовать
echo "Testing shared PostgreSQL ($SHARED_POSTGRES_HOST:$SHARED_POSTGRES_PORT)..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$SHARED_POSTGRES_HOST/$SHARED_POSTGRES_PORT"; then
  echo '✓ Shared PostgreSQL is reachable'
  FINAL_POSTGRES_HOST="$SHARED_POSTGRES_HOST"
  USE_SHARED=true
else
  echo '✗ Shared PostgreSQL not reachable, testing fallback...'
  
  # Проверяем fallback PostgreSQL
  if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$FALLBACK_POSTGRES_HOST/$FALLBACK_POSTGRES_PORT"; then
    echo '✓ Fallback PostgreSQL is reachable'
    FINAL_POSTGRES_HOST="$FALLBACK_POSTGRES_HOST"
    USE_SHARED=false
  else
    echo '✗ Both PostgreSQL servers are unreachable'
    exit 1
  fi
fi

echo "Configuration:"
echo "  PostgreSQL Host: $FINAL_POSTGRES_HOST:5432"
echo "  Admin User: $POSTGRES_ADMIN_USER"
echo "  Metabase DB User: $METABASE_DB_USER"
echo "  Metabase DB Name: $METABASE_DB_NAME"
echo "  Using: $($USE_SHARED && echo 'SHARED' || echo 'FALLBACK') database"

# Для shared PostgreSQL проверяем существование пользователя/БД
if [ "$USE_SHARED" = true ]; then
  echo "Checking if user and database exist in shared PostgreSQL..."
  
  # Проверяем существует ли пользователь
  USER_EXISTS=$(PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$FINAL_POSTGRES_HOST" -U "$POSTGRES_ADMIN_USER" -d postgres -t -c \
    "SELECT 1 FROM pg_roles WHERE rolname='$METABASE_DB_USER';" 2>/dev/null | tr -d '[:space:]')
  
  # Проверяем существует ли БД
  DB_EXISTS=$(PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$FINAL_POSTGRES_HOST" -U "$POSTGRES_ADMIN_USER" -d postgres -t -c \
    "SELECT 1 FROM pg_database WHERE datname='$METABASE_DB_NAME';" 2>/dev/null | tr -d '[:space:]')
  
  if [ "$USER_EXISTS" = "1" ] && [ "$DB_EXISTS" = "1" ]; then
    echo '✓ User and database already exist in shared PostgreSQL'
  else
    echo 'Creating user and database in shared PostgreSQL...'
    
    # Создаем пользователя если не существует
    if [ "$USER_EXISTS" != "1" ]; then
      PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$FINAL_POSTGRES_HOST" -U "$POSTGRES_ADMIN_USER" -d postgres -c \
        "CREATE USER \"$METABASE_DB_USER\" WITH PASSWORD '$METABASE_DB_PASSWORD';" 2>/dev/null && \
        echo '✓ User created' || echo '✗ User creation failed'
    fi
    
    # Создаем БД если не существует
    if [ "$DB_EXISTS" != "1" ]; then
      PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$FINAL_POSTGRES_HOST" -U "$POSTGRES_ADMIN_USER" -d postgres -c \
        "CREATE DATABASE \"$METABASE_DB_NAME\" OWNER \"$METABASE_DB_USER\";" 2>/dev/null && \
        echo '✓ Database created' || echo '✗ Database creation failed'
    fi
  fi
else
  # Для fallback всегда создаем (он должен быть пустым)
  echo 'Creating user and database in fallback PostgreSQL...'
  
  PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$FINAL_POSTGRES_HOST" -U "$POSTGRES_ADMIN_USER" -d postgres -c \
    "CREATE USER \"$METABASE_DB_USER\" WITH PASSWORD '$METABASE_DB_PASSWORD';" 2>/dev/null && \
    echo '✓ User created' || echo '⚠ User creation (might already exist)'
  
  PGPASSWORD="$POSTGRES_ADMIN_PASSWORD" psql -h "$FINAL_POSTGRES_HOST" -U "$POSTGRES_ADMIN_USER" -d postgres -c \
    "CREATE DATABASE \"$METABASE_DB_NAME\" OWNER \"$METABASE_DB_USER\";" 2>/dev/null && \
    echo '✓ Database created' || echo '⚠ Database creation (might already exist)'
fi

# Записываем финальный хост в переменную для Docker Compose
echo "METABASE_FINAL_DB_HOST=$FINAL_POSTGRES_HOST" > /tmp/db_host.env

echo '=== METABASE DATABASE INITIALIZATION COMPLETED ==='
exit 0
