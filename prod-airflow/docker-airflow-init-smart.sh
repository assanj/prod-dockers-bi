#!/bin/bash
echo '=== AIRFLOW DATABASE INITIALIZATION ==='

# Читаем переменные окружения
POSTGRES_HOST="${POSTGRES_HOST:-prod-postgres}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_ADMIN_USER="${POSTGRES_ADMIN_USER:-postgres}"
POSTGRES_ADMIN_PASSWORD="${POSTGRES_ADMIN_PASSWORD:-postgres}"

AIRFLOW_DB_USER="${AIRFLOW_DB_USER:-airflow}"
AIRFLOW_DB_PASSWORD="${AIRFLOW_DB_PASSWORD:-airflow}"
AIRFLOW_DB_NAME="${AIRFLOW_DB_NAME:-airflow}"
AIRFLOW_FERNET_KEY="${AIRFLOW_FERNET_KEY:-}"

echo "Configuration:"
echo "  PostgreSQL Host: $POSTGRES_HOST:$POSTGRES_PORT"
echo "  Admin User: $POSTGRES_ADMIN_USER"
echo "  Airflow DB User: $AIRFLOW_DB_USER"
echo "  Airflow DB Name: $AIRFLOW_DB_NAME"

# Проверяем доступность shared PostgreSQL
echo "Testing shared PostgreSQL ($POSTGRES_HOST:$POSTGRES_PORT)..."
if timeout 5 bash -c "cat < /dev/null > /dev/tcp/$POSTGRES_HOST/$POSTGRES_PORT"; then
  echo '✓ Shared PostgreSQL is reachable'
  
  # Пытаемся подключиться с airflow credentials
  echo 'Testing Airflow credentials...'
  python3 -c "
import psycopg2
try:
    conn = psycopg2.connect(
        host='$POSTGRES_HOST',
        port=$POSTGRES_PORT,
        dbname='$AIRFLOW_DB_NAME',
        user='$AIRFLOW_DB_USER',
        password='$AIRFLOW_DB_PASSWORD',
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
    echo '✓ Airflow credentials work, using SHARED database'
    export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql+psycopg2://$AIRFLOW_DB_USER:$AIRFLOW_DB_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$AIRFLOW_DB_NAME"
  else
    echo '✗ Airflow credentials failed, CREATING USER AND DATABASE...'
    
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
    cur.execute(\"SELECT 1 FROM pg_roles WHERE rolname='$AIRFLOW_DB_USER'\")
    if not cur.fetchone():
        cur.execute(\"CREATE USER \\\"$AIRFLOW_DB_USER\\\" WITH PASSWORD '$AIRFLOW_DB_PASSWORD'\")
        print('User $AIRFLOW_DB_USER created')
    else:
        print('User $AIRFLOW_DB_USER already exists')
    
    # Создаем БД если не существует  
    cur.execute(\"SELECT 1 FROM pg_database WHERE datname='$AIRFLOW_DB_NAME'\")
    if not cur.fetchone():
        cur.execute(\"CREATE DATABASE \\\"$AIRFLOW_DB_NAME\\\" OWNER \\\"$AIRFLOW_DB_USER\\\"\")
        print('Database $AIRFLOW_DB_NAME created')
    else:
        print('Database $AIRFLOW_DB_NAME already exists')
    
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
      export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN="postgresql+psycopg2://$AIRFLOW_DB_USER:$AIRFLOW_DB_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$AIRFLOW_DB_NAME"
    else
      echo '✗ Failed to create user/database, Airflow cannot work without database'
      exit 1
    fi
  fi
else
  echo '✗ Shared PostgreSQL not reachable, Airflow cannot work without database'
  exit 1
fi

echo "Using database: $AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"

# Записываем переменную в файл
echo "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" > /tmp/airflow_database_url.txt
echo "AIRFLOW__CELERY__RESULT_BACKEND=db+postgresql://$AIRFLOW_DB_USER:$AIRFLOW_DB_PASSWORD@$POSTGRES_HOST:$POSTGRES_PORT/$AIRFLOW_DB_NAME" >> /tmp/airflow_database_url.txt
echo "AIRFLOW__CELERY__BROKER_URL=redis://redis:6379/0" >> /tmp/airflow_database_url.txt

# Генерируем Fernet key если не задан
if [ -z "$AIRFLOW_FERNET_KEY" ]; then
  echo "Generating new Fernet key..."
  AIRFLOW_FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
  echo "Generated Fernet key"
fi

echo "AIRFLOW__CORE__FERNET_KEY=$AIRFLOW_FERNET_KEY" >> /tmp/airflow_database_url.txt

# Standard Airflow initialization через Python с правильными env variables
python3 -c "
import os
import subprocess

# Читаем URL базы данных из файла
with open('/tmp/airflow_database_url.txt', 'r') as f:
    for line in f:
        if '=' in line:
            key, value = line.strip().split('=', 1)
            os.environ[key] = value
            print(f'Set {key}')

# Запускаем Airflow команды
try:
    subprocess.run(['airflow', 'db', 'init'], check=True)
    subprocess.run(['airflow', 'users', 'create',
                    '--username', 'admin',
                    '--firstname', 'Admin',
                    '--lastname', 'User',
                    '--role', 'Admin',
                    '--email', 'admin@example.com',
                    '--password', 'admin'], check=True)
    print('SUCCESS: Airflow initialized')
except subprocess.CalledProcessError as e:
    print(f'FAILED: {e}')
    exit(1)
"
