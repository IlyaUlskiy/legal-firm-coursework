import os

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    MYSQL_HOST = 'localhost'
    MYSQL_USER = 'root'
    MYSQL_PASSWORD = 'Digrel4ik'
    MYSQL_DB = 'kursach'
    MYSQL_CURSORCLASS = 'DictCursor'