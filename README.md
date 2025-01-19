```markdown
# FreeWay Matrix Installer 🚀

Автоматический скрипт для установки Matrix Synapse в Docker с поддержкой Nginx и SSL.

---

## Запуск скрипта

```bash
sudo ./freeway-matrix.sh
```

Введите:
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
