#!/bin/bash
echo '=== DATABASE INITIALIZATION ==='

# Читаем переменные окружения
POSTGRES_HOST="${DATABASE_HOST:-prod-postgres}"
POSTGRES_PORT="${DATABASE_PORT:-5432}"
POSTGRES_ADMIN_USER="${POSTGRES_ADMIN_USER:-postgres}"
POSTGRES_ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-postgres}"

SUPERSET_DB_USER="${DATABASE_USER:-superset}"
SUPERSET_DB_PASSWORD="${DATABASE_PASSWORD:-superset}"
SUPERSET_DB_NAME="${DATABASE_DB:-superset}"

echo "Configuration:"
echo "  PostgreSQL Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "  Admin User: $POSTGRES_ADMIN_USER"
echo "  Superset DB User: $SUPERSET_DB_USER"
echo "  Superset DB Name: $SUPERSET_DB_NAME"

# Проверяем доступность shared PostgreSQL
echo "Testing shared PostgreSQL ($POSTGRES_HOST:$POSTGRES_PORT)..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$POSTGRES_HOST/$POSTGRES_PORT"; then
  echo '✓ Shared PostgreSQL is reachable'
  
  # Пытаемся подключиться с superset credentials
  echo 'Testing superset credentials...'
  python3 -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='$POSTGRES_HOST',
        port=$POSTGRES_PORT,
        dbname='$SUPERSET_DB_NAME',
        user='$SUPERSET_DB_USER',
        password='$SUPERSET_DB_PASSWORD',
        connect_timeout=3
    )
    conn.close()
    print('SUCCESS')
    exit(0)
except Exception as e:
    print(f'FAILED: {e}')
    exit(1)
  "
  
  if [ $? -eq 0 ]; then
    echo '✓ Superset credentials work, using SHARED database'
    export SUPERSET__SQLALCHEMY_DATABASE_URI="postgresql+psycopg2://$SUPERSET_DB_USER:$SUPERSET_DB_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$SUPERSET_DB_NAME"
  else
    echo '✗ Superset credentials failed, CREATING USER AND DATABASE...'
    
    # Создаем пользователя и БД через Python
    python3 -c "
import psycopg2
try:
    # Подключаемся как admin для создания пользователя
    conn = psycopg2.connect(
        host='$POSTGRES_HOST',
        port=$POSTGRES_PORT,
        dbname='postgres',
        user='$POSTGRES_ADMIN_USER',
        password='$POSTGRES_ADMIN_PASSWORD',
        connect_timeout=3
    )
    conn.autocommit = True
    cur = conn.cursor()
    
    # Создаем пользователя если не существует
    cur.execute(\"SELECT 1 FROM pg_roles WHERE rolname='$SUPERSET_DB_USER'\")
    if not cur.fetchone():
        cur.execute(\"CREATE USER \\\"$SUPERSET_DB_USER\\\" WITH PASSWORD '$SUPERSET_DB_PASSWORD'\")
        print('User $SUPERSET_DB_USER created')
    else:
        print('User $SUPERSET_DB_USER already exists')
    
    # Создаем БД если не существует  
    cur.execute(\"SELECT 1 FROM pg_database WHERE datname='$SUPERSET_DB_NAME'\")
    if not cur.fetchone():
        cur.execute(\"CREATE DATABASE \\\"$SUPERSET_DB_NAME\\\" OWNER \\\"$SUPERSET_DB_USER\\\"\")
        print('Database $SUPERSET_DB_NAME created')
    else:
        print('Database $SUPERSET_DB_NAME already exists')
    
    cur.close()
    conn.close()
    print('SUCCESS: User and database created')
    exit(0)
except Exception as e:
    print(f'FAILED to create user/database: {e}')
    exit(1)
    "
    
    if [ $? -eq 0 ]; then
      echo '✓ User and database created, using SHARED database'
      export SUPERSET__SQLALCHEMY_DATABASE_URI="postgresql+psycopg2://$SUPERSET_DB_USER:$SUPERSET_DB_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$SUPERSET_DB_NAME"
    else
      echo '✗ Failed to create user/database, using LOCAL database'
      export SUPERSET__SQLALCHEMY_DATABASE_URI="postgresql+psycopg2://${DATABASE_USER:-superset}:${DATABASE_PASSWORD:-superset}@superset_db:5432/${DATABASE_DB:-superset}"
    fi
  fi
else
  echo '✗ Shared PostgreSQL not reachable, using LOCAL database'
  export SUPERSET__SQLALCHEMY_DATABASE_URI="postgresql+psycopg2://${DATABASE_USER:-superset}:${DATABASE_PASSWORD:-superset}@superset_db:5432/${DATABASE_DB:-superset}"
fi

echo "Using database: $SUPERSET__SQLALCHEMY_DATABASE_URI"

# Записываем переменную в файл
echo "SUPERSET__SQLALCHEMY_DATABASE_URI=$SUPERSET__SQLALCHEMY_DATABASE_URI" > /tmp/database_url.txt

# Standard Superset initialization через Python с правильными env variables
python3 -c "
import os
import subprocess

# Читаем URL базы данных из файла
with open('/tmp/database_url.txt', 'r') as f:
    for line in f:
        if 'SUPERSET__SQLALCHEMY_DATABASE_URI' in line:
            key, value = line.strip().split('=', 1)
            os.environ[key] = value
            print(f'Set {key}')

# Запускаем Superset команды
try:
    subprocess.run(['superset', 'db', 'upgrade'], check=True)
    subprocess.run(['superset', 'fab', 'create-admin', 
                    '--username', 'admin', 
                    '--email', 'admin@example.com', 
                    '--password', 'admin', 
                    '--firstname', 'Admin', 
                    '--lastname', 'User'], check=True) 
    subprocess.run(['superset', 'init'], check=True)
    print('SUCCESS: Superset initialized')
except subprocess.CalledProcessError as e:
    print(f'FAILED: {e}')
    exit(1)
"
