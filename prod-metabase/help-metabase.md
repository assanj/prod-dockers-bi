docker compose up -d
docker logs metabase_init


# 1. Удалите старый контейнер
docker rm -f metabase_init 2>/dev/null || true

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

# 4. Открываем в браузере + на внешних
echo "http://localhost:3000"


docker logs metabase 2>&1 | tail -50

HOST_IP=$(hostname -I | awk '{print $1}')
curl http://$HOST_IP:3000/api/health && echo " ✓"
