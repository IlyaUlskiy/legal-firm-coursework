from werkzeug.security import generate_password_hash

# Генерация новых хешей с современным алгоритмом
passwords = {
    'admin': 'admin123',
    'manager1': 'manager123',
    'manager2': 'manager123',
    'lawyer1': 'lawyer123',
    'lawyer2': 'lawyer123',
    'lawyer3': 'lawyer123',
    'lawyer4': 'lawyer123',
    'lawyer5': 'lawyer123'
}

print("Новые хеши паролей для обновления в БД:\n")
for username, password in passwords.items():
    hash = generate_password_hash(password, method='pbkdf2:sha256')
    print(f"UPDATE users SET password_hash = '{hash}' WHERE username = '{username}';")