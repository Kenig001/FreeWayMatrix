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


