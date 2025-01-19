# FreeWay Matrix Installer 🚀

**FreeWay Matrix** — это скрипт, который:

- **Устанавливает** [Matrix Synapse](https://github.com/matrix-org/synapse) в Docker.
- Настраивает **Nginx** в качестве обратного прокси с Let’s Encrypt (SSL).
- **Открывает** порты через UFW (22, 80, 443, 8008, 8448).
- Спрашивает только **домен** и **email**, всё остальное делает автоматически.

---

## Возможности ⚡
1. **Простая установка Synapse**: Разворачивает сервер Matrix в Docker, плюс Nginx-прокси.  
2. **Автоматическая настройка SSL**: Certbot и Let’s Encrypt выдают сертификаты.  
3. **UFW**: Позаботится о необходимых портах.  
4. **Минимум вопросов**: Только ваш домен и почта для Let’s Encrypt.

---

## Требования ❗
- **Ubuntu/Debian** (или совместимые)  
- **root-доступ** (или `sudo`)  
- Порты **80 и 443** должны быть **свободны**. Если у вас есть Apache/Nginx, лучше временно выключить.

---

## Установка и запуск ❓
1. **Скачать скрипт**:
   ```bash
   wget https://raw.githubusercontent.com/<ВашНик>/FreeWayMatrix/main/freeway-matrix.sh
   chmod +x freeway-matrix.sh
Запустить:
sudo ./freeway-matrix.sh
Ввести:
Домен (например, matrix.example.com)
Email (для Let’s Encrypt)
Скрипт:

Поставит нужные пакеты (docker.io, docker-compose, ufw, certbot).
Настроит UFW и откроет порты.
Выпустит сертификаты Let’s Encrypt.
Сгенерирует docker-compose.yml и nginx.conf.
Поднимет контейнеры с Synapse и Nginx.
Результат 🎉
Matrix-сервер: Synapse слушает http://synapse:8008 внутри Docker, наружу выходит через Nginx.
Nginx: Порты 80 (редирект) и 443 (HTTPS).
SSL: Файлы в /etc/letsencrypt/live/<домен>.
Рабочий Matrix: Доступен по https://<домен>. Федерация тоже будет идти на 443.
Проверка 👀
curl:
bash
Копировать
curl -k https://<домен>/_matrix/client/versions
Будет JSON о версиях Matrix API.
Клиент (Element и др.):
Задайте https://<домен> как homeserver.
Попробуйте зарегистрироваться или войти.
