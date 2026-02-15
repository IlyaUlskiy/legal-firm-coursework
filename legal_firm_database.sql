-- MySQL dump 10.13  Distrib 8.0.44, for Win64 (x86_64)
--
-- Host: localhost    Database: kursach
-- ------------------------------------------------------
-- Server version	8.0.44

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `audit_log`
--

DROP TABLE IF EXISTS `audit_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_log` (
  `log_id` bigint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор записи аудита',
  `user_id` int unsigned NOT NULL COMMENT 'Пользователь, выполнивший операцию',
  `action_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Тип операции (CREATE, UPDATE, DELETE)',
  `table_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Имя таблицы',
  `record_id` int unsigned NOT NULL COMMENT 'Идентификатор записи в таблице',
  `old_values` json DEFAULT NULL COMMENT 'Старые значения (для UPDATE/DELETE)',
  `new_values` json DEFAULT NULL COMMENT 'Новые значения (для CREATE/UPDATE)',
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IP-адрес клиента',
  `action_timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата и время операции',
  PRIMARY KEY (`log_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_table_record` (`table_name`,`record_id`),
  KEY `idx_action_timestamp` (`action_timestamp`),
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_log`
--

LOCK TABLES `audit_log` WRITE;
/*!40000 ALTER TABLE `audit_log` DISABLE KEYS */;
INSERT INTO `audit_log` VALUES (1,2,'CREATE','clients',1,NULL,'{\"phone\": \"+7 (900) 111-11-11\", \"full_name\": \"Соколов Алексей Владимирович\"}','192.168.1.100','2026-01-10 02:15:23'),(2,2,'CREATE','cases',1,NULL,'{\"client_id\": 1, \"status_id\": 1, \"case_number\": \"ГР-2026-0001\"}','192.168.1.100','2026-01-10 02:20:45'),(3,4,'UPDATE','cases',1,'{\"status_id\": 1}','{\"status_id\": 2}','192.168.1.101','2026-01-15 07:30:12'),(4,4,'UPDATE','cases',1,'{\"status_id\": 2}','{\"status_id\": 4}','192.168.1.101','2026-02-15 09:45:33'),(5,3,'CREATE','clients',3,NULL,'{\"phone\": \"+7 (900) 333-33-33\", \"full_name\": \"Морозов Дмитрий Игоревич\"}','192.168.1.102','2026-01-20 03:05:18'),(6,6,'CREATE','hearings',3,NULL,'{\"case_id\": 3, \"hearing_date\": \"2026-02-05 09:30:00\"}','192.168.1.103','2026-01-25 04:20:40'),(7,7,'CREATE','documents',9,NULL,'{\"case_id\": 4, \"document_name\": \"Исковое заявление о взыскании задолженности\"}','192.168.1.104','2026-01-25 06:15:22'),(8,5,'CREATE','comments',3,NULL,'{\"case_id\": 2, \"comment_text\": \"Подготовлены документы для предварительного слушания.\"}','192.168.1.105','2026-01-28 07:20:00'),(9,2,'DELETE','clients',11,'{\"phone\": \"+7 (999) 000-00-00\", \"full_name\": \"Тестовый клиент\"}',NULL,'192.168.1.100','2026-01-30 02:10:55');
/*!40000 ALTER TABLE `audit_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `case_categories`
--

DROP TABLE IF EXISTS `case_categories`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `case_categories` (
  `category_id` tinyint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор категории',
  `category_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название категории',
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `uk_category_name` (`category_name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `case_categories`
--

LOCK TABLES `case_categories` WRITE;
/*!40000 ALTER TABLE `case_categories` DISABLE KEYS */;
INSERT INTO `case_categories` VALUES (1,'Имущественные споры'),(4,'Корпоративные конфликты'),(5,'Наследственные дела'),(2,'Семейные дела'),(3,'Трудовые споры');
/*!40000 ALTER TABLE `case_categories` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `case_statuses`
--

DROP TABLE IF EXISTS `case_statuses`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `case_statuses` (
  `status_id` tinyint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор статуса',
  `status_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название статуса',
  PRIMARY KEY (`status_id`),
  UNIQUE KEY `uk_status_name` (`status_name`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `case_statuses`
--

LOCK TABLES `case_statuses` WRITE;
/*!40000 ALTER TABLE `case_statuses` DISABLE KEYS */;
INSERT INTO `case_statuses` VALUES (2,'В работе'),(4,'Завершено'),(3,'На рассмотрении суда'),(1,'Новое'),(5,'Отказано');
/*!40000 ALTER TABLE `case_statuses` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `case_types`
--

DROP TABLE IF EXISTS `case_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `case_types` (
  `type_id` tinyint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор типа',
  `type_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название типа дела',
  PRIMARY KEY (`type_id`),
  UNIQUE KEY `uk_type_name` (`type_name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `case_types`
--

LOCK TABLES `case_types` WRITE;
/*!40000 ALTER TABLE `case_types` DISABLE KEYS */;
INSERT INTO `case_types` VALUES (4,'Административное'),(3,'Арбитражное'),(1,'Гражданское'),(2,'Уголовное');
/*!40000 ALTER TABLE `case_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `cases`
--

DROP TABLE IF EXISTS `cases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `cases` (
  `case_id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор дела',
  `case_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Уникальный номер дела (ТИП-ГОД-ПОРЯДКОВЫЙ_НОМЕР)',
  `client_id` int unsigned NOT NULL COMMENT 'Клиент по делу',
  `lawyer_id` int unsigned NOT NULL COMMENT 'Ответственный юрист',
  `manager_id` int unsigned NOT NULL COMMENT 'Менеджер, открывший дело',
  `status_id` tinyint unsigned NOT NULL COMMENT 'Текущий статус дела',
  `type_id` tinyint unsigned NOT NULL COMMENT 'Тип дела',
  `category_id` tinyint unsigned NOT NULL COMMENT 'Категория дела',
  `description` text COLLATE utf8mb4_unicode_ci COMMENT 'Описание предмета спора',
  `open_date` date NOT NULL DEFAULT (curdate()) COMMENT 'Дата открытия дела',
  `close_date` date DEFAULT NULL COMMENT 'Дата закрытия дела',
  PRIMARY KEY (`case_id`),
  UNIQUE KEY `uk_case_number` (`case_number`),
  KEY `idx_client_id` (`client_id`),
  KEY `idx_lawyer_id` (`lawyer_id`),
  KEY `idx_manager_id` (`manager_id`),
  KEY `idx_status_id` (`status_id`),
  KEY `idx_open_date` (`open_date`),
  KEY `fk_cases_type` (`type_id`),
  KEY `fk_cases_category` (`category_id`),
  CONSTRAINT `fk_cases_category` FOREIGN KEY (`category_id`) REFERENCES `case_categories` (`category_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_cases_client` FOREIGN KEY (`client_id`) REFERENCES `clients` (`client_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_cases_lawyer` FOREIGN KEY (`lawyer_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_cases_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_cases_status` FOREIGN KEY (`status_id`) REFERENCES `case_statuses` (`status_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_cases_type` FOREIGN KEY (`type_id`) REFERENCES `case_types` (`type_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `cases`
--

LOCK TABLES `cases` WRITE;
/*!40000 ALTER TABLE `cases` DISABLE KEYS */;
INSERT INTO `cases` VALUES (1,'ГР-2026-0001',1,4,2,4,1,1,'Иск о взыскании денежных средств по договору займа. Сумма иска: 500 000 руб.','2026-01-10','2026-02-15'),(2,'ГР-2026-0002',2,5,2,2,1,2,'Расторжение брака, раздел имущества и определение места жительства детей','2026-01-15',NULL),(3,'УГ-2026-0003',3,6,3,3,2,1,'Защита по обвинению в мошенничестве (ч. 2 ст. 159 УК РФ)','2026-01-20',NULL),(4,'АР-2026-0004',4,7,3,4,3,4,'Спор о взыскании задолженности по договору поставки. Сумма: 2 500 000 руб.','2026-01-25','2026-02-20'),(5,'АД-2026-0005',5,8,2,1,4,1,'Обжалование постановления о привлечении к административной ответственности по ст. 12.15 КоАП РФ','2026-02-01',NULL),(6,'ГР-2026-0006',6,4,3,2,1,3,'Взыскание заработной платы за период работы. Сумма: 180 000 руб.','2026-02-05',NULL),(7,'ГР-2026-0007',7,5,2,4,1,5,'Оспаривание завещания и раздел наследственного имущества','2026-02-08','2026-02-25'),(8,'УГ-2026-0008',8,6,3,2,2,1,'Защита по обвинению в причинении вреда здоровью средней тяжести (ст. 112 УК РФ)','2026-02-10',NULL),(10,'ГР-2026-0010',10,8,3,1,1,2,'Установление отцовства и взыскание алиментов на содержание ребёнка','2026-02-15',NULL),(11,'ГР-2026-0011',1,4,2,2,1,1,'Защита интересов ответчика по иску о защите прав потребителей','2026-02-18',NULL),(12,'ГР-2026-0012',3,5,3,4,1,1,'Взыскание ущерба от ДТП в порядке регресса. Сумма: 350 000 руб.','2026-02-20','2026-03-01'),(13,'АД-2026-0013',5,6,2,5,4,1,'Обжалование отказа в выдаче разрешения на строительство','2026-02-22','2026-03-05'),(14,'ГР-2026-0014',7,7,3,2,1,2,'Раздел совместно нажитого имущества супругов после развода','2026-02-25',NULL),(15,'УГ-2026-0015',9,8,2,3,2,1,'Защита по обвинению в краже (ч. 1 ст. 158 УК РФ)','2026-02-28',NULL);
/*!40000 ALTER TABLE `cases` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_cases_before_insert` BEFORE INSERT ON `cases` FOR EACH ROW BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*) INTO v_count
    FROM cases
    WHERE case_number = NEW.case_number;
    
    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ошибка: Номер дела уже существует в системе';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_cases_after_insert` AFTER INSERT ON `cases` FOR EACH ROW BEGIN
    INSERT INTO audit_log (
        user_id, action_type, table_name, record_id, new_values, ip_address, action_timestamp
    )
    VALUES (
        @current_user_id,
        'CREATE',
        'cases',
        NEW.case_id,
        JSON_OBJECT(
            'case_number', NEW.case_number,
            'client_id', NEW.client_id,
            'lawyer_id', NEW.lawyer_id,
            'status_id', NEW.status_id,
            'open_date', NEW.open_date
        ),
        @current_ip,
        NOW()
    );
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `clients`
--

DROP TABLE IF EXISTS `clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `clients` (
  `client_id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор клиента',
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ФИО клиента',
  `phone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Контактный телефон',
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Электронная почта',
  `passport_data` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Паспортные данные (серия, номер, кем выдан)',
  `registration_date` date NOT NULL DEFAULT (curdate()) COMMENT 'Дата регистрации в системе',
  `manager_id` int unsigned NOT NULL COMMENT 'Менеджер, зарегистрировавший клиента',
  PRIMARY KEY (`client_id`),
  KEY `idx_manager_id` (`manager_id`),
  KEY `idx_full_name` (`full_name`),
  CONSTRAINT `fk_clients_manager` FOREIGN KEY (`manager_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `clients`
--

LOCK TABLES `clients` WRITE;
/*!40000 ALTER TABLE `clients` DISABLE KEYS */;
INSERT INTO `clients` VALUES (1,'Соколов Алексей Владимирович','+7 (900) 111-11-11','sokolov@example.com','45 00 111111, выдан ОВД района Центральный г. Москвы','2026-02-10',2),(2,'Кузнецова Ольга Сергеевна','+7 (900) 222-22-22','kuznetsova@example.com','45 00 222222, выдан ОВД района Басманный г. Москвы','2026-02-10',2),(3,'Морозов Дмитрий Игоревич','+7 (900) 333-33-33','morozov@example.com','45 00 333333, выдан ОВД района Красносельский г. Москвы','2026-02-10',3),(4,'Волкова Екатерина Андреевна','+7 (900) 444-44-44','volkova@example.com','45 00 444444, выдан ОВД района Тверской г. Москвы','2026-02-10',3),(5,'Зайцев Павел Николаевич','+7 (900) 555-55-55','zaitsev@example.com','45 00 555555, выдан ОВД района Пресненский г. Москвы','2026-02-10',2),(6,'Семёнова Татьяна Валерьевна','+7 (900) 666-66-66','semenova@example.com','45 00 666666, выдан ОВД района Хамовники г. Москвы','2026-02-10',3),(7,'Попов Максим Юрьевич','+7 (900) 777-77-77','popov@example.com','45 00 777777, выдан ОВД района Арбат г. Москвы','2026-02-10',2),(8,'Лебедева Наталья Александровна','+7 (900) 888-88-88','lebedeva@example.com','45 00 888888, выдан ОВД района Якиманка г. Москвы','2026-02-10',3),(9,'Козлов Игорь Викторович','+7 (900) 999-99-99','kozlov@example.com','45 00 999999, выдан ОВД района Замоскворечье г. Москвы','2026-02-10',2),(10,'Федорова Марина Павловна','+7 (901) 111-11-11','fedorova@example.com','45 01 111111, выдан ОВД района Таганский г. Москвы','2026-02-10',3);
/*!40000 ALTER TABLE `clients` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_clients_before_delete` BEFORE DELETE ON `clients` FOR EACH ROW BEGIN
    DECLARE v_case_count INT;
    
    SELECT COUNT(*) INTO v_case_count
    FROM cases
    WHERE client_id = OLD.client_id;
    
    IF v_case_count > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Невозможно удалить клиента: у него есть связанные дела';
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `comments`
--

DROP TABLE IF EXISTS `comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `comments` (
  `comment_id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор комментария',
  `case_id` int unsigned NOT NULL COMMENT 'Дело, к которому относится комментарий',
  `user_id` int unsigned NOT NULL COMMENT 'Автор комментария',
  `comment_text` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Текст комментария',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания комментария',
  PRIMARY KEY (`comment_id`),
  KEY `idx_case_id` (`case_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_created_at` (`created_at`),
  CONSTRAINT `fk_comments_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`case_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_comments_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `comments`
--

LOCK TABLES `comments` WRITE;
/*!40000 ALTER TABLE `comments` DISABLE KEYS */;
INSERT INTO `comments` VALUES (1,1,4,'Клиент доволен результатом. Получены исполнительные листы.','2026-02-16 02:30:00'),(2,1,4,'Необходимо контролировать исполнение решения суда.','2026-02-16 02:35:00'),(3,2,5,'Подготовлены документы для предварительного слушания.','2026-01-28 07:20:00'),(4,2,5,'Клиент просит ускорить рассмотрение дела.','2026-01-30 04:15:00'),(5,3,6,'Подана жалоба на постановление следователя.','2026-01-25 09:45:00'),(6,3,6,'Назначена встреча с клиентом для обсуждения стратегии защиты.','2026-02-01 03:00:00'),(7,4,7,'Дело выиграно полностью. Клиент доволен.','2026-02-21 02:10:00'),(8,5,8,'Подготовлена жалоба в вышестоящую инстанцию.','2026-02-05 06:25:00'),(9,6,4,'Получены документы от бухгалтерии ответчика.','2026-02-10 08:40:00'),(10,7,5,'Суд удовлетворил иск частично. Клиент обжалует решение.','2026-02-26 04:20:00'),(11,8,6,'Назначен судебно-медицинский эксперт.','2026-02-15 07:50:00'),(13,10,8,'Назначена генетическая экспертиза.','2026-02-18 02:45:00'),(14,11,4,'Подготовлены возражения на исковые требования.','2026-02-20 09:15:00'),(15,12,5,'Решение суда вступило в законную силу.','2026-03-02 03:05:00'),(16,13,6,'Подана кассационная жалоба.','2026-03-06 07:30:00'),(17,14,7,'Назначено медиативное соглашение сторон.','2026-02-28 04:55:00'),(18,15,8,'Клиент не выходит на связь. Необходимо отправить уведомление.','2026-03-01 02:20:00');
/*!40000 ALTER TABLE `comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `document_types`
--

DROP TABLE IF EXISTS `document_types`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `document_types` (
  `type_id` tinyint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор типа',
  `type_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название типа документа',
  PRIMARY KEY (`type_id`),
  UNIQUE KEY `uk_doc_type_name` (`type_name`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `document_types`
--

LOCK TABLES `document_types` WRITE;
/*!40000 ALTER TABLE `document_types` DISABLE KEYS */;
INSERT INTO `document_types` VALUES (4,'Договор'),(7,'Заключение эксперта'),(1,'Исковое заявление'),(5,'Переписка'),(6,'Протокол заседания'),(3,'Решение суда'),(2,'Ходатайство');
/*!40000 ALTER TABLE `document_types` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `documents`
--

DROP TABLE IF EXISTS `documents`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `documents` (
  `document_id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор документа',
  `case_id` int unsigned NOT NULL COMMENT 'Дело, к которому относится документ',
  `type_id` tinyint unsigned NOT NULL COMMENT 'Тип документа',
  `document_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Наименование документа',
  `file_path` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Путь к файлу в файловой системе',
  `uploaded_by` int unsigned NOT NULL COMMENT 'Пользователь, загрузивший документ',
  `upload_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата загрузки',
  PRIMARY KEY (`document_id`),
  KEY `idx_case_id` (`case_id`),
  KEY `idx_type_id` (`type_id`),
  KEY `idx_upload_date` (`upload_date`),
  KEY `fk_documents_uploader` (`uploaded_by`),
  CONSTRAINT `fk_documents_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`case_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_documents_type` FOREIGN KEY (`type_id`) REFERENCES `document_types` (`type_id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_documents_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `documents`
--

LOCK TABLES `documents` WRITE;
/*!40000 ALTER TABLE `documents` DISABLE KEYS */;
INSERT INTO `documents` VALUES (1,1,1,'Исковое заявление о взыскании денежных средств','/uploads/case_1/isk_1.pdf',4,'2026-02-10 13:22:14'),(2,1,3,'Решение суда от 15.02.2026','/uploads/case_1/reshenie_1.pdf',4,'2026-02-10 13:22:14'),(3,1,6,'Протокол судебного заседания от 25.01.2026','/uploads/case_1/protokol_1.pdf',4,'2026-02-10 13:22:14'),(4,2,1,'Исковое заявление о расторжении брака','/uploads/case_2/isk_2.pdf',5,'2026-02-10 13:22:14'),(5,2,4,'Брачный договор','/uploads/case_2/dogovor.pdf',5,'2026-02-10 13:22:14'),(6,2,5,'Переписка с ответчиком','/uploads/case_2/perepiska.pdf',5,'2026-02-10 13:22:14'),(7,3,1,'Ходатайство об избрании меры пресечения','/uploads/case_3/hodatajstvo_1.pdf',6,'2026-02-10 13:22:14'),(8,3,2,'Заявление о назначении экспертизы','/uploads/case_3/zayavlenie.pdf',6,'2026-02-10 13:22:14'),(9,4,1,'Исковое заявление о взыскании задолженности','/uploads/case_4/isk_4.pdf',7,'2026-02-10 13:22:14'),(10,4,3,'Решение арбитражного суда','/uploads/case_4/reshenie_4.pdf',7,'2026-02-10 13:22:14'),(11,4,6,'Протокол заседания от 10.02.2026','/uploads/case_4/protokol_4.pdf',7,'2026-02-10 13:22:14'),(12,5,1,'Жалоба на постановление об административном правонарушении','/uploads/case_5/zhaloba.pdf',8,'2026-02-10 13:22:14'),(13,6,1,'Исковое заявление о взыскании заработной платы','/uploads/case_6/isk_6.pdf',4,'2026-02-10 13:22:14'),(14,6,7,'Заключение бухгалтерской экспертизы','/uploads/case_6/ekspertiza.pdf',4,'2026-02-10 13:22:14'),(15,7,1,'Исковое заявление об оспаривании завещания','/uploads/case_7/isk_7.pdf',5,'2026-02-10 13:22:14'),(16,7,3,'Решение суда от 25.02.2026','/uploads/case_7/reshenie_7.pdf',5,'2026-02-10 13:22:14'),(17,8,2,'Ходатайство о проведении следственного эксперимента','/uploads/case_8/hodatajstvo.pdf',6,'2026-02-10 13:22:14'),(19,10,1,'Исковое заявление об установлении отцовства','/uploads/case_10/isk_10.pdf',8,'2026-02-10 13:22:14'),(20,11,2,'Возражения на исковые требования','/uploads/case_11/vozrazheniya.pdf',4,'2026-02-10 13:22:14'),(21,12,1,'Исковое заявление о взыскании ущерба от ДТП','/uploads/case_12/isk_12.pdf',5,'2026-02-10 13:22:14'),(22,12,3,'Решение суда от 01.03.2026','/uploads/case_12/reshenie_12.pdf',5,'2026-02-10 13:22:14'),(23,13,1,'Административная жалоба','/uploads/case_13/zhaloba_13.pdf',6,'2026-02-10 13:22:14'),(24,13,3,'Решение суда об отказе','/uploads/case_13/reshenie_13.pdf',6,'2026-02-10 13:22:14'),(25,14,1,'Исковое заявление о разделе имущества','/uploads/case_14/isk_14.pdf',7,'2026-02-10 13:22:14'),(26,15,2,'Ходатайство об отложении судебного заседания','/uploads/case_15/hodatajstvo.pdf',8,'2026-02-10 13:22:14'),(27,15,4,'фыв','/uploads/case_15/document_1770733649.057019.pdf',1,'2026-02-10 14:27:29');
/*!40000 ALTER TABLE `documents` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hearings`
--

DROP TABLE IF EXISTS `hearings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hearings` (
  `hearing_id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор заседания',
  `case_id` int unsigned NOT NULL COMMENT 'Дело, к которому относится заседание',
  `hearing_date` datetime NOT NULL COMMENT 'Дата и время заседания',
  `court_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Наименование суда',
  `courtroom` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Номер зала заседаний',
  `result` text COLLATE utf8mb4_unicode_ci COMMENT 'Результат/протокол заседания',
  `created_by` int unsigned NOT NULL COMMENT 'Пользователь, создавший запись',
  PRIMARY KEY (`hearing_id`),
  KEY `idx_case_id` (`case_id`),
  KEY `idx_hearing_date` (`hearing_date`),
  KEY `fk_hearings_creator` (`created_by`),
  CONSTRAINT `fk_hearings_case` FOREIGN KEY (`case_id`) REFERENCES `cases` (`case_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_hearings_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hearings`
--

LOCK TABLES `hearings` WRITE;
/*!40000 ALTER TABLE `hearings` DISABLE KEYS */;
INSERT INTO `hearings` VALUES (1,1,'2026-01-25 10:00:00','Московский городской суд','Зал 101','Принято решение о взыскании денежных средств в пользу истца',4),(2,1,'2026-02-10 11:30:00','Московский городской суд','Зал 101','Заседание по вопросу исполнения решения суда',4),(3,2,'2026-02-01 14:00:00','Тверской районный суд г. Москвы','Зал 205','Назначено предварительное слушание на 15.02.2026',5),(4,3,'2026-02-05 09:30:00','Басманный районный суд г. Москвы','Зал 301','Избрана мера пресечения - подписка о невыезде',6),(5,3,'2026-02-20 10:00:00','Басманный районный суд г. Москвы','Зал 301','Назначено судебное заседание на 10.03.2026',6),(6,4,'2026-02-10 13:00:00','Арбитражный суд г. Москвы','Зал 50','Принято решение о взыскании задолженности в полном объёме',7),(7,6,'2026-02-20 15:00:00','Пресненский районный суд г. Москвы','Зал 15','Назначено заседание на 05.03.2026',4),(8,7,'2026-02-15 11:00:00','Хамовнический районный суд г. Москвы','Зал 42','Принято решение об удовлетворении иска частично',5),(9,7,'2026-02-25 14:30:00','Хамовнический районный суд г. Москвы','Зал 42','Заседание по вопросу исполнения решения',5),(10,8,'2026-03-01 10:00:00','Якиманский районный суд г. Москвы','Зал 28','Назначено предварительное слушание',6),(12,12,'2026-02-25 10:30:00','Замоскворецкий районный суд г. Москвы','Зал 12','Принято решение о взыскании ущерба',5),(13,12,'2026-03-01 14:00:00','Замоскворецкий районный суд г. Москвы','Зал 12','Заседание по вопросу исполнения решения',5),(14,13,'2026-03-01 09:00:00','Таганский районный суд г. Москвы','Зал 35','Принято решение об отказе в удовлетворении жалобы',6),(15,13,'2026-03-05 11:00:00','Таганский районный суд г. Москвы','Зал 35','Заседание по вопросу обжалования решения',6),(17,11,'2026-02-10 21:43:00','das',NULL,NULL,4);
/*!40000 ALTER TABLE `hearings` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER `trg_hearings_after_insert` AFTER INSERT ON `hearings` FOR EACH ROW BEGIN
    DECLARE v_current_status TINYINT UNSIGNED;
    
    SELECT status_id INTO v_current_status
    FROM cases
    WHERE case_id = NEW.case_id;
    
    IF v_current_status = 2 THEN
        UPDATE cases
        SET status_id = 3
        WHERE case_id = NEW.case_id;
        
        INSERT INTO audit_log (user_id, action_type, table_name, record_id, old_values, new_values, action_timestamp)
        VALUES (
            @current_user_id,
            'AUTO_UPDATE',
            'cases',
            NEW.case_id,
            '{"status_id":2}',
            '{"status_id":3}',
            NOW()
        );
    END IF;
END */;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `user_roles`
--

DROP TABLE IF EXISTS `user_roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_roles` (
  `role_id` tinyint unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор роли',
  `role_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Название роли (Администратор, Менеджер, Юрист)',
  PRIMARY KEY (`role_id`),
  UNIQUE KEY `uk_role_name` (`role_name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_roles`
--

LOCK TABLES `user_roles` WRITE;
/*!40000 ALTER TABLE `user_roles` DISABLE KEYS */;
INSERT INTO `user_roles` VALUES (1,'Администратор'),(2,'Менеджер'),(3,'Юрист');
/*!40000 ALTER TABLE `user_roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int unsigned NOT NULL AUTO_INCREMENT COMMENT 'Идентификатор пользователя',
  `username` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Логин для входа',
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Хеш пароля (bcrypt)',
  `role_id` tinyint unsigned NOT NULL COMMENT 'Роль пользователя',
  `full_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'ФИО сотрудника',
  `email` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Электронная почта',
  `is_active` tinyint(1) NOT NULL DEFAULT '1' COMMENT 'Статус учётной записи',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Дата создания учётной записи',
  `last_login` timestamp NULL DEFAULT NULL COMMENT 'Дата последнего входа',
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `uk_username` (`username`),
  UNIQUE KEY `uk_email` (`email`),
  KEY `idx_role_id` (`role_id`),
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `user_roles` (`role_id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'admin','pbkdf2:sha256:600000$dsqCLD8BBTEr9qRT$c009d88afb35d3234b0faf965372338edea3ed2cc5774bb59e4d9a028bf7a2fa',1,'Администратор Системы','admin@firm.ru',1,'2026-02-10 13:21:53','2026-02-13 10:33:22'),(2,'manager1','pbkdf2:sha256:600000$KtJCDz4WvT8SuTYY$5b26cdfbad085e13ad82231f5c144b0301f9080d250fb20fd52c7371fb086d1d',2,'Иванов Иван Иванович','manager1@firm.ru',1,'2026-02-10 13:21:53','2026-02-10 15:32:50'),(3,'manager2','pbkdf2:sha256:600000$FI4jaCo6Pm6QdRAw$ee8c1f2150e214bd13fa22e6b39da104d110cee6ddc76152d7d7d189a63bcc69',2,'Сидорова Мария Петровна','manager2@firm.ru',1,'2026-02-10 13:21:53',NULL),(4,'lawyer1','pbkdf2:sha256:600000$Rjfh870uVjTSrdKa$72e0263a293c0cf0fa831d7f9d3bb3fd25b30e03a94ebd9e593c22adc65ad7f7',3,'Петров Сергей Александрович','lawyer1@firm.ru',1,'2026-02-10 13:21:53','2026-02-10 15:03:19'),(5,'lawyer2','pbkdf2:sha256:600000$PrsxzzP3x0saX3mH$6fe142ccf8970addd4c032b1efef41c73d610a16761eeeafec512f9541517f26',3,'Козлова Анна Владимировна','lawyer2@firm.ru',1,'2026-02-10 13:21:53',NULL),(6,'lawyer3','pbkdf2:sha256:600000$dYtQU93yiOCnA9Mu$2104ea8c7d530ee83463305d79fe99f1a57d076319da0279c63bfd7568c25d7d',3,'Смирнов Дмитрий Николаевич','lawyer3@firm.ru',1,'2026-02-10 13:21:53',NULL),(7,'lawyer4','pbkdf2:sha256:600000$vtAJLX7A4emv8fG3$7cad164eec5b6404b976cab5fffd4b57653b8cb09473b5eac1ff389e84704a7f',3,'Васильева Елена Сергеевна','lawyer4@firm.ru',1,'2026-02-10 13:21:53',NULL),(8,'lawyer5','pbkdf2:sha256:600000$AvHJtIgsRkY5GRJA$d0f9829bb72ab7ead8bf28d4f45ce12647d04dd1570ae502a880f785add762a6',3,'Николаев Андрей Викторович','lawyer5@firm.ru',1,'2026-02-10 13:21:53',NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Temporary view structure for view `vw_active_cases`
--

DROP TABLE IF EXISTS `vw_active_cases`;
/*!50001 DROP VIEW IF EXISTS `vw_active_cases`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_active_cases` AS SELECT 
 1 AS `case_id`,
 1 AS `case_number`,
 1 AS `description`,
 1 AS `open_date`,
 1 AS `client_name`,
 1 AS `client_phone`,
 1 AS `lawyer_name`,
 1 AS `status_name`,
 1 AS `type_name`,
 1 AS `category_name`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_lawyer_statistics`
--

DROP TABLE IF EXISTS `vw_lawyer_statistics`;
/*!50001 DROP VIEW IF EXISTS `vw_lawyer_statistics`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_lawyer_statistics` AS SELECT 
 1 AS `user_id`,
 1 AS `lawyer_name`,
 1 AS `total_cases`,
 1 AS `in_progress_cases`,
 1 AS `completed_cases`*/;
SET character_set_client = @saved_cs_client;

--
-- Dumping events for database 'kursach'
--

--
-- Dumping routines for database 'kursach'
--
/*!50003 DROP PROCEDURE IF EXISTS `sp_archive_old_cases` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_archive_old_cases`(
    OUT p_archived_count INT,
    OUT p_error_message VARCHAR(255)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_error_message = 'Ошибка при архивации дел';
        SET p_archived_count = 0;
    END;
    
    START TRANSACTION;
    
    CREATE TABLE IF NOT EXISTS cases_archive LIKE cases;
    
    INSERT INTO cases_archive
    SELECT * FROM cases
    WHERE status_id = 4 
      AND close_date < DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
      AND case_id NOT IN (SELECT case_id FROM cases_archive);
    
    SET p_archived_count = ROW_COUNT();
    
    DELETE c FROM cases c
    INNER JOIN cases_archive ca ON c.case_id = ca.case_id;
    
    COMMIT;
    SET p_error_message = NULL;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_close_case` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_close_case`(
    IN p_case_id INT UNSIGNED,
    OUT p_result VARCHAR(100)
)
BEGIN
    DECLARE v_current_status TINYINT UNSIGNED;
    
    SELECT status_id INTO v_current_status
    FROM cases
    WHERE case_id = p_case_id;
    
    IF v_current_status IS NULL THEN
        SET p_result = 'Ошибка: Дело не найдено';
    ELSEIF v_current_status = 4 THEN
        SET p_result = 'Информация: Дело уже завершено';
    ELSE
        UPDATE cases
        SET status_id = 4,
            close_date = CURRENT_DATE
        WHERE case_id = p_case_id;
        
        SET p_result = CONCAT('Успех: Дело №', p_case_id, ' завершено');
        
        INSERT INTO audit_log (user_id, action_type, table_name, record_id, old_values, new_values, ip_address, action_timestamp)
        VALUES (
            @current_user_id, 
            'CLOSE', 
            'cases', 
            p_case_id,
            CONCAT('{"status_id":', v_current_status, '}'),
            CONCAT('{"status_id":4, "close_date":"', CURRENT_DATE, '"}'),
            @current_ip,
            NOW()
        );
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_generate_lawyer_report` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_generate_lawyer_report`(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    IF p_start_date > p_end_date THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Ошибка: Начальная дата не может быть больше конечной';
    END IF;
    
    SELECT 
        u.user_id AS lawyer_id,
        u.full_name AS lawyer_name,
        COUNT(c.case_id) AS total_cases,
        SUM(CASE WHEN c.status_id = 2 THEN 1 ELSE 0 END) AS in_progress_cases,
        SUM(CASE WHEN c.status_id = 4 THEN 1 ELSE 0 END) AS completed_cases,
        ROUND(AVG(DATEDIFF(
            IF(c.close_date IS NULL, CURRENT_DATE, c.close_date), 
            c.open_date
        )), 1) AS avg_days_open,
        GROUP_CONCAT(DISTINCT ct.type_name SEPARATOR ', ') AS case_types
    FROM users u
    LEFT JOIN cases c ON u.user_id = c.lawyer_id 
        AND c.open_date BETWEEN p_start_date AND p_end_date
    LEFT JOIN case_types ct ON c.type_id = ct.type_id
    WHERE u.role_id = 3 
      AND u.is_active = TRUE
    GROUP BY u.user_id, u.full_name
    ORDER BY total_cases DESC;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_get_cases_by_status` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_get_cases_by_status`(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT 
        cs.status_id,
        cs.status_name,
        COUNT(c.case_id) AS case_count,
        ROUND(COUNT(c.case_id) * 100.0 / SUM(COUNT(c.case_id)) OVER (), 1) AS percentage
    FROM case_statuses cs
    LEFT JOIN cases c ON cs.status_id = c.status_id 
        AND c.open_date BETWEEN p_start_date AND p_end_date
    GROUP BY cs.status_id, cs.status_name
    ORDER BY cs.status_id;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 DROP PROCEDURE IF EXISTS `sp_update_case_status` */;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb4 */ ;
/*!50003 SET character_set_results = utf8mb4 */ ;
/*!50003 SET collation_connection  = utf8mb4_0900_ai_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_update_case_status`(
    IN p_case_id INT UNSIGNED,
    IN p_new_status_id TINYINT UNSIGNED,
    IN p_user_id INT UNSIGNED,
    OUT p_success BOOLEAN,
    OUT p_message VARCHAR(255)
)
BEGIN
    DECLARE v_current_status TINYINT UNSIGNED;
    DECLARE v_hearing_count INT;
    
    SELECT status_id INTO v_current_status
    FROM cases WHERE case_id = p_case_id;
    
    IF v_current_status IS NULL THEN
        SET p_success = FALSE;
        SET p_message = 'Ошибка: Дело не найдено';
    ELSEIF v_current_status = p_new_status_id THEN
        SET p_success = FALSE;
        SET p_message = 'Информация: Статус не изменён (уже установлен)';
    ELSEIF p_new_status_id = 4 THEN
        SELECT COUNT(*) INTO v_hearing_count
        FROM hearings WHERE case_id = p_case_id;
        
        IF v_hearing_count = 0 THEN
            SET p_success = FALSE;
            SET p_message = 'Ошибка: Нельзя завершить дело без проведения заседаний';
        ELSE
            UPDATE cases SET status_id = p_new_status_id WHERE case_id = p_case_id;
            INSERT INTO audit_log (user_id, action_type, table_name, record_id, old_values, new_values)
            VALUES (
                p_user_id, 'UPDATE_STATUS', 'cases', p_case_id,
                CONCAT('{"status_id":', v_current_status, '}'),
                CONCAT('{"status_id":', p_new_status_id, '}')
            );
            SET p_success = TRUE;
            SET p_message = CONCAT('Статус дела №', p_case_id, ' успешно изменён');
        END IF;
    ELSEIF v_current_status = 5 THEN
        SET p_success = FALSE;
        SET p_message = 'Ошибка: Дело со статусом "Отказано" нельзя изменить';
    ELSE
        UPDATE cases SET status_id = p_new_status_id WHERE case_id = p_case_id;
        INSERT INTO audit_log (user_id, action_type, table_name, record_id, old_values, new_values)
        VALUES (
            p_user_id, 'UPDATE_STATUS', 'cases', p_case_id,
            CONCAT('{"status_id":', v_current_status, '}'),
            CONCAT('{"status_id":', p_new_status_id, '}')
        );
        SET p_success = TRUE;
        SET p_message = CONCAT('Статус дела №', p_case_id, ' успешно изменён');
    END IF;
END ;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Final view structure for view `vw_active_cases`
--

/*!50001 DROP VIEW IF EXISTS `vw_active_cases`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_active_cases` AS select `c`.`case_id` AS `case_id`,`c`.`case_number` AS `case_number`,`c`.`description` AS `description`,`c`.`open_date` AS `open_date`,`cl`.`full_name` AS `client_name`,`cl`.`phone` AS `client_phone`,`u`.`full_name` AS `lawyer_name`,`cs`.`status_name` AS `status_name`,`ct`.`type_name` AS `type_name`,`cc`.`category_name` AS `category_name` from (((((`cases` `c` join `clients` `cl` on((`c`.`client_id` = `cl`.`client_id`))) join `users` `u` on((`c`.`lawyer_id` = `u`.`user_id`))) join `case_statuses` `cs` on((`c`.`status_id` = `cs`.`status_id`))) join `case_types` `ct` on((`c`.`type_id` = `ct`.`type_id`))) join `case_categories` `cc` on((`c`.`category_id` = `cc`.`category_id`))) where (`c`.`status_id` not in (4,5)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_lawyer_statistics`
--

/*!50001 DROP VIEW IF EXISTS `vw_lawyer_statistics`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_lawyer_statistics` AS select `u`.`user_id` AS `user_id`,`u`.`full_name` AS `lawyer_name`,count(`c`.`case_id`) AS `total_cases`,sum((case when (`c`.`status_id` = 2) then 1 else 0 end)) AS `in_progress_cases`,sum((case when (`c`.`status_id` = 4) then 1 else 0 end)) AS `completed_cases` from (`users` `u` left join `cases` `c` on(((`u`.`user_id` = `c`.`lawyer_id`) and (`u`.`role_id` = 3)))) group by `u`.`user_id`,`u`.`full_name` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-02-16  2:08:30
