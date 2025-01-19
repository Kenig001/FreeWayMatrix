FreeWay Matrix Installer 🚀
Добро пожаловать в FreeWay Matrix — скрипт, который:

Автоматически устанавливает Matrix Synapse через Docker и Nginx-прокси с Let’s Encrypt (SSL).
Открывает необходимые порты в UFW и запрашивает у вас домен + email.
После завершения вы получаете готовый Matrix-сервер, доступный по HTTPS на вашем домене!
Возможности ⚡
Простая установка Synapse: Автоматически разворачивает сервер Matrix в Docker с Nginx-прокси.
Настройка SSL: Использует certbot и Let’s Encrypt для выпуска сертификатов.
Открытие портов: Автоматически разрешает (UFW) порты 22, 80, 443, 8008, 8448.
Минимум вопросов: Только домен и email для сертификатов, остальное происходит автоматически.
Требования ❗
Ubuntu/Debian-подобная система с поддержкой apt-get.
root-права (или sudo), так как скрипт ставит пакеты и настраивает firewall.
Порты 80 и 443 должны быть свободны, чтобы certbot смог получить сертификаты (не должно быть другого веб-сервера, слушающего эти порты).
Как использовать ❓
Скачайте скрипт:
bash
Копировать
wget https://raw.githubusercontent.com/<ВашНик>/FreeWayMatrix/main/freeway-matrix.sh
chmod +x freeway-matrix.sh
Запустите:
bash
Копировать
sudo ./freeway-matrix.sh
Введите:
Домен (например, matrix.example.com)
E-mail (для Let’s Encrypt)
Скрипт:
Установит docker.io, docker-compose, ufw, certbot.
Настроит ufw и откроет порты.
Сгенерирует сертификаты.
Создаст docker-compose.yml и nginx.conf.
Поднимет Synapse и Nginx в контейнерах.
Результат 🎉
Matrix-сервер Synapse (порт 8008 внутри контейнера, доступен извне через Nginx).
Nginx (порт 80 → редирект на 443, а 443 → прокси на Synapse).
SSL-сертификаты в /etc/letsencrypt/live/<домен>.
Рабочий Matrix по https://<домен> (федерация на 443).
Проверка 👀
curl:
bash
Копировать
curl -k https://<домен>/_matrix/client/versions
Получите JSON о версиях API.
Клиент:
Укажите https://<домен> в Element (или другом клиенте Matrix).
Примечания 📝
Если уже запущен Nginx/Apache, нужно их остановить, чтобы 80 порт был свободен.
При желании изменить путь или структуру — редактируйте docker-compose.yml и nginx.conf.
