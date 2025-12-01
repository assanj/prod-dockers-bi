# 1. Переходим в папку PostgreSQL
cd ~/prod-dockers-bi/prod-postgres

# 2. Останавливаем контейнер И УДАЛЯЕМ ТОМ (-v)
docker compose down -v

# 3. Ждем полной остановки
sleep 2

# 4. Запускаем заново
docker compose up -d

# 5. Даем время на запуск
sleep 5

# 6. Проверяем что контейнер запущен
docker ps | grep postgres

# 7. Тестируем подключение
docker run -it --rm --network prod-postgres_bi-network \
  postgres:16 psql -h prod-postgres -U postgres -d postgres -c "SELECT 1;"
  

## Команды для перезапуска PostgreSQL контейнера:

### 1. Быстрый перезапуск (сохраняет данные)
```bash
cd ~/prod-dockers-bi/prod-postgres
docker compose restart
```

### 2. Полный перезапуск (с пересозданием контейнера)
```bash
cd ~/prod-dockers-bi/prod-postgres
docker compose down
docker compose up -d
```

### 3. Перезапуск только PostgreSQL контейнера
```bash
docker restart prod-postgres
```

### 4. Перезапуск с принудительным пересозданием
```bash
cd ~/prod-dockers-bi/prod-postgres
docker compose up -d --force-recreate
```

### 5. Перезапуск с просмотром логов
```bash
cd ~/prod-dockers-bi/prod-postgres
docker compose down
docker compose up -d
docker logs prod-postgres -f
```

### 6. Проверка статуса после перезапуска
```bash
docker ps | grep postgres
docker logs prod-postgres --tail 10
```

**Для обычного использования достаточно команды №1 или №2.**





docker exec shared_postgres psql -U postgres -c "\l"
docker exec shared_postgres psql -U postgres -c "\du"
