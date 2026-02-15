markdown
# База данных для курсовой работы  

## Как импортировать базу данных
1. Создайте пустую базу данных в MySQL:
   ```sql
   CREATE DATABASE legal_firm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
2. Импортируйте дамп через командную строку:
    mysql -u root -p legal_firm < legal_firm_database.sql

3. Или импортируйте через DBeaver:
Правой кнопкой по базе → Tools → Restore Database
Укажите путь к файлу legal_firm_database.sql
Нажмите Start

Требования: MySQL 8.0+, поддержка движка InnoDB, Клиент DBeaver 25.3+ (или любой MySQL-клиент)
