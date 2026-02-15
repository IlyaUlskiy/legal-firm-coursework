markdown
# База данных для курсовой работы  
**Тема:** Учёт дел, клиентов и судебных заседаний в юридической фирме

## Как импортировать базу данных
1. Создайте пустую базу данных в MySQL:
   ```sql
   CREATE DATABASE legal_firm CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
Импортируйте структуру:
mysql -u root -p legal_firm < database_schema.sql

Импортируйте данные:
mysql -u root -p legal_firm < database_data.sql

Импортируйте процедуры и триггеры:
mysql -u root -p legal_firm < procedures_triggers.sql

Требования: MySQL 8.0+, поддержка движка InnoDB.
