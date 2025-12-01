docker compose up -d
docker logs metabase_init

# Останавливаем Metabase (контейнеры останавливаются, тома сохраняются)
docker compose down
# Или только остановка без удаления
docker compose stop



cd ~/prod-dockers-bi/metabase

# 1. Проверяем что скрипт существует и исполняемый
ls -la docker-metabase-init.sh
chmod +x docker-metabase-init.sh

# 2. Запускаем Metabase
docker compose up -d

# 3. Проверяем логи
docker logs metabase_init
docker logs metabase

# 4. Открываем в браузере
echo "http://localhost:3000"
