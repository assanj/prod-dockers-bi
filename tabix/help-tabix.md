# Создаем папку для Tabix
mkdir -p ~/prod-dockers-bi/tabix
cd ~/prod-dockers-bi/tabix

# Создаем docker-compose.yml
# Копируем конфиг выше

# Запускаем
docker compose up -d

# Проверяем
docker ps | grep tabix
docker logs tabix

# Открываем
echo "Tabix доступен: http://localhost:8080"
