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
**Запуск**
   
    sudo ./freeway-matrix.sh


3. Введите:
   - **Домен** (например, `matrix.example.com`)
   - **Email** (для Let’s Encrypt)

---

## Что делает скрипт?

1. Устанавливает необходимые пакеты: `docker.io`, `docker-compose`, `ufw`, `certbot`.
2. Настраивает **UFW** и открывает порты (22, 80, 443, 8008, 8448).
3. Выпускает **Let’s Encrypt** сертификаты.
4. Создаёт файлы `docker-compose.yml` и `nginx.conf`.
5. Запускает контейнеры **Synapse** и **Nginx**.

---

## Результат 🎉

- **Matrix-сервер**:
  Synapse работает внутри Docker на `http://synapse:8008`, а снаружи доступен через Nginx.
- **Nginx**:
  Порты `80` (HTTP-редирект) и `443` (HTTPS).
- **SSL**:
  Сертификаты хранятся в `/etc/letsencrypt/live/<домен>`.
- **Доступный Matrix**:
  Сервер доступен по адресу `https://<домен>`, включая поддержку федерации.

---

## Проверка 👀

### cURL

```bash
curl -k https://<домен>/_matrix/client/versions
```

Результат: JSON с версиями Matrix API.

### Клиент (Element и другие)

1. Укажите `https://<домен>` как homeserver.
2. Попробуйте зарегистрироваться или войти.

---

### Автор

**Создано Kenig01 ❤️**
```

