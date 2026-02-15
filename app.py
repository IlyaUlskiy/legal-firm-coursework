from flask import Flask, render_template, request, redirect, url_for, flash, session, make_response
import csv
from io import StringIO
from flask import Flask, render_template, request, redirect, url_for, flash, session
from flask_mysqldb import MySQL
from werkzeug.security import generate_password_hash, check_password_hash
import os
from datetime import datetime
from config import Config

app = Flask(__name__)
app.config.from_object(Config)

# Инициализация БД
mysql = MySQL(app)


# ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========

def get_db():
    """Получение соединения с БД"""
    return mysql.connection


def generate_case_number(type_id, case_id):
    """Генерация уникального номера дела: ТИП-ГОД-ПОРЯДКОВЫЙ_НОМЕР"""
    type_prefix = {
        1: 'ГР',  # Гражданское
        2: 'УГ',  # Уголовное
        3: 'АР',  # Арбитражное
        4: 'АД'  # Административное
    }
    prefix = type_prefix.get(type_id, 'ДЕЛО')
    year = datetime.now().year
    return f"{prefix}-{year}-{case_id:04d}"


# ========== МАРШРУТЫ АВТОРИЗАЦИИ ==========

@app.route('/login', methods=['GET', 'POST'])
def login():
    """Страница авторизации"""
    if 'user_id' in session:
        return redirect(url_for('dashboard'))

    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        if not username or not password:
            flash('Введите логин и пароль', 'danger')
            return render_template('login.html')

        connection = get_db()
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM users WHERE username = %s", (username,))
            user = cursor.fetchone()

        if user and check_password_hash(user['password_hash'], password):
            session['user_id'] = user['user_id']
            session['username'] = user['username']
            session['role_id'] = user['role_id']
            session['full_name'] = user['full_name']

            # Обновление времени последнего входа
            connection = get_db()
            with connection.cursor() as cursor:
                cursor.execute("UPDATE users SET last_login = NOW() WHERE user_id = %s", (user['user_id'],))
                connection.commit()

            flash(f'Добро пожаловать, {user["full_name"]}!', 'success')
            return redirect(url_for('dashboard'))
        else:
            flash('Неверный логин или пароль', 'danger')
            return render_template('login.html')

    return render_template('login.html')


@app.route('/logout')
def logout():
    """Выход из системы"""
    session.clear()
    flash('Вы успешно вышли из системы', 'info')
    return redirect(url_for('login'))


# ========== МАРШРУТЫ ГЛАВНОЙ СТРАНИЦЫ ==========

@app.route('/')
def index():
    """Перенаправление на дэшборд или логин"""
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))


@app.route('/dashboard')
def dashboard():
    """Главная страница - дэшборд"""
    if 'user_id' not in session:
        return redirect(url_for('login'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Статистика
        cursor.execute("SELECT COUNT(*) as count FROM cases")
        total_cases = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM cases WHERE status_id NOT IN (4, 5)")
        active_cases = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM clients")
        total_clients = cursor.fetchone()['count']

        cursor.execute("SELECT COUNT(*) as count FROM users WHERE role_id = 3 AND is_active = TRUE")
        total_lawyers = cursor.fetchone()['count']

        # Последние 5 дел
        cursor.execute("""
            SELECT c.case_id, c.case_number, c.open_date, c.description,
                   cl.full_name AS client_name,
                   u.full_name AS lawyer_name,
                   cs.status_id,  -- Добавлено
                   cs.status_name
            FROM cases c
            JOIN clients cl ON c.client_id = cl.client_id
            JOIN users u ON c.lawyer_id = u.user_id
            JOIN case_statuses cs ON c.status_id = cs.status_id
            ORDER BY c.open_date DESC
            LIMIT 5
        """)
        recent_cases = cursor.fetchall()

        # Активные дела для юриста
        user_cases = []
        if session['role_id'] == 3:  # Юрист
            cursor.execute("""
                SELECT c.case_id, c.case_number, c.open_date, c.description,
                       cl.full_name AS client_name,
                       cs.status_name
                FROM cases c
                JOIN clients cl ON c.client_id = cl.client_id
                JOIN case_statuses cs ON c.status_id = cs.status_id
                WHERE c.lawyer_id = %s AND c.status_id NOT IN (4, 5)
                ORDER BY c.open_date DESC
            """, (session['user_id'],))
            user_cases = cursor.fetchall()

    return render_template('dashboard.html',
                           total_cases=total_cases,
                           active_cases=active_cases,
                           total_clients=total_clients,
                           total_lawyers=total_lawyers,
                           recent_cases=recent_cases,
                           user_cases=user_cases,
                           role_id=session['role_id'])


# ========== МАРШРУТЫ КЛИЕНТОВ ==========

@app.route('/clients')
def clients():
    """Список клиентов"""
    if 'user_id' not in session:
        return redirect(url_for('login'))

    search = request.args.get('search', '').strip()

    connection = get_db()
    with connection.cursor() as cursor:
        # Для юристов показываем только своих клиентов
        if session['role_id'] == 3:
            if search:
                cursor.execute("""
                    SELECT c.*, u.full_name AS manager_name,
                           (SELECT COUNT(*) FROM cases WHERE client_id = c.client_id) AS cases_count
                    FROM clients c
                    JOIN users u ON c.manager_id = u.user_id
                    WHERE c.full_name LIKE %s
                    AND c.client_id IN (
                        SELECT client_id FROM cases WHERE lawyer_id = %s
                    )
                    ORDER BY c.registration_date DESC
                """, (f'%{search}%', session['user_id']))
            else:
                cursor.execute("""
                    SELECT c.*, u.full_name AS manager_name,
                           (SELECT COUNT(*) FROM cases WHERE client_id = c.client_id) AS cases_count
                    FROM clients c
                    JOIN users u ON c.manager_id = u.user_id
                    WHERE c.client_id IN (
                        SELECT client_id FROM cases WHERE lawyer_id = %s
                    )
                    ORDER BY c.registration_date DESC
                """, (session['user_id'],))
        else:
            # Для администраторов и менеджеров - все клиенты
            if search:
                cursor.execute("""
                    SELECT c.*, u.full_name AS manager_name,
                           (SELECT COUNT(*) FROM cases WHERE client_id = c.client_id) AS cases_count
                    FROM clients c
                    JOIN users u ON c.manager_id = u.user_id
                    WHERE c.full_name LIKE %s
                    ORDER BY c.registration_date DESC
                """, (f'%{search}%',))
            else:
                cursor.execute("""
                    SELECT c.*, u.full_name AS manager_name,
                           (SELECT COUNT(*) FROM cases WHERE client_id = c.client_id) AS cases_count
                    FROM clients c
                    JOIN users u ON c.manager_id = u.user_id
                    ORDER BY c.registration_date DESC
                """)

        clients_list = cursor.fetchall()

    return render_template('clients.html',
                           clients=clients_list,
                           search_query=search,
                           role_id=session['role_id'])


@app.route('/clients/new', methods=['GET', 'POST'])
def add_client():
    """Добавление нового клиента"""
    if 'user_id' not in session or session['role_id'] not in [1, 2]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('clients'))

    if request.method == 'POST':
        full_name = request.form.get('full_name', '').strip()
        phone = request.form.get('phone', '').strip()
        email = request.form.get('email', '').strip()
        passport_data = request.form.get('passport_data', '').strip()

        if not all([full_name, phone, passport_data]):
            flash('Заполните все обязательные поля', 'danger')
            return render_template('client_form.html', mode='add')

        connection = get_db()
        with connection.cursor() as cursor:
            # Проверка уникальности телефона
            cursor.execute("SELECT client_id FROM clients WHERE phone = %s", (phone,))
            if cursor.fetchone():
                flash(f'Клиент с телефоном {phone} уже существует', 'warning')
                return render_template('client_form.html', mode='add',
                                       full_name=full_name, phone=phone,
                                       email=email, passport_data=passport_data)

            # Вставка клиента
            cursor.execute("""
                INSERT INTO clients (full_name, phone, email, passport_data, manager_id)
                VALUES (%s, %s, %s, %s, %s)
            """, (full_name, phone, email if email else None, passport_data, session['user_id']))

            connection.commit()

        flash('Клиент успешно добавлен', 'success')
        return redirect(url_for('clients'))

    return render_template('client_form.html', mode='add')


@app.route('/clients/<int:client_id>/edit', methods=['GET', 'POST'])
def edit_client(client_id):
    """Редактирование клиента"""
    if 'user_id' not in session or session['role_id'] not in [1, 2]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('clients'))

    connection = get_db()
    with connection.cursor() as cursor:
        cursor.execute("SELECT * FROM clients WHERE client_id = %s", (client_id,))
        client = cursor.fetchone()

        if not client:
            flash('Клиент не найден', 'danger')
            return redirect(url_for('clients'))

        if request.method == 'POST':
            full_name = request.form.get('full_name', '').strip()
            phone = request.form.get('phone', '').strip()
            email = request.form.get('email', '').strip()
            passport_data = request.form.get('passport_data', '').strip()

            if not all([full_name, phone, passport_data]):
                flash('Заполните все обязательные поля', 'danger')
                return render_template('client_form.html', mode='edit', client=client)

            # Проверка уникальности телефона (кроме текущего клиента)
            cursor.execute("SELECT client_id FROM clients WHERE phone = %s AND client_id != %s",
                           (phone, client_id))
            if cursor.fetchone():
                flash(f'Клиент с телефоном {phone} уже существует', 'warning')
                return render_template('client_form.html', mode='edit', client=client)

            # Обновление клиента
            cursor.execute("""
                UPDATE clients
                SET full_name = %s, phone = %s, email = %s, passport_data = %s
                WHERE client_id = %s
            """, (full_name, phone, email if email else None, passport_data, client_id))

            connection.commit()
            flash('Клиент успешно обновлён', 'success')  # ✅ Внутри блока POST
            return redirect(url_for('clients'))  # ✅ Редирект после обновления

        return render_template('client_form.html', mode='edit', client=client)


@app.route('/clients/<int:client_id>/delete', methods=['POST'])
def delete_client(client_id):
    """Удаление клиента"""
    if 'user_id' not in session or session['role_id'] not in [1, 2]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('clients'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Проверка наличия связанных дел
        cursor.execute("SELECT COUNT(*) as count FROM cases WHERE client_id = %s", (client_id,))
        result = cursor.fetchone()

        if result['count'] > 0:
            flash(f'Нельзя удалить клиента, у которого есть {result["count"]} дела(ел)', 'danger')
            return redirect(url_for('clients'))

        # Удаление клиента
        cursor.execute("DELETE FROM clients WHERE client_id = %s", (client_id,))
        connection.commit()

    flash('Клиент успешно удалён', 'success')
    return redirect(url_for('clients'))


# ========== МАРШРУТЫ ДЕЛ ==========

@app.route('/cases')
def cases():
    """Список дел"""
    if 'user_id' not in session:
        return redirect(url_for('login'))

    # Получение параметров фильтрации
    status_id = request.args.get('status_id', type=int)
    type_id = request.args.get('type_id', type=int)
    category_id = request.args.get('category_id', type=int)
    search = request.args.get('search', '').strip()

    connection = get_db()
    with connection.cursor() as cursor:
        # Загрузка справочников
        cursor.execute("SELECT status_id, status_name FROM case_statuses ORDER BY status_id")
        statuses = cursor.fetchall()

        cursor.execute("SELECT type_id, type_name FROM case_types ORDER BY type_id")
        types = cursor.fetchall()

        cursor.execute("SELECT category_id, category_name FROM case_categories ORDER BY category_id")
        categories = cursor.fetchall()

        # Формирование запроса
        base_sql = """
            SELECT c.*, 
                   cl.full_name AS client_name,
                   u.full_name AS lawyer_name,
                   m.full_name AS manager_name,
                   cs.status_name,
                   ct.type_name,
                   cc.category_name
            FROM cases c
            JOIN clients cl ON c.client_id = cl.client_id
            JOIN users u ON c.lawyer_id = u.user_id
            JOIN users m ON c.manager_id = m.user_id
            JOIN case_statuses cs ON c.status_id = cs.status_id
            JOIN case_types ct ON c.type_id = ct.type_id
            JOIN case_categories cc ON c.category_id = cc.category_id
            WHERE 1=1
        """
        params = []

        if status_id:
            base_sql += " AND c.status_id = %s"
            params.append(status_id)

        if type_id:
            base_sql += " AND c.type_id = %s"
            params.append(type_id)

        if category_id:
            base_sql += " AND c.category_id = %s"
            params.append(category_id)

        if search:
            base_sql += " AND c.case_number LIKE %s"
            params.append(f'%{search}%')

        # Фильтрация для юристов
        if session['role_id'] == 3:
            base_sql += " AND c.lawyer_id = %s"
            params.append(session['user_id'])

        base_sql += " ORDER BY c.open_date DESC"

        cursor.execute(base_sql, params)
        cases_list = cursor.fetchall()

    return render_template('cases.html',
                           cases=cases_list,
                           statuses=statuses,
                           types=types,
                           categories=categories,
                           selected_status=status_id,
                           selected_type=type_id,
                           selected_category=category_id,
                           search_query=search,
                           role_id=session['role_id'])


@app.route('/cases/new', methods=['GET', 'POST'])
def add_case():
    """Добавление нового дела"""
    if 'user_id' not in session or session['role_id'] not in [1, 2]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Загрузка данных для формы
        cursor.execute("SELECT client_id, full_name FROM clients ORDER BY full_name")
        clients = cursor.fetchall()

        cursor.execute("SELECT user_id, full_name FROM users WHERE role_id = 3 AND is_active = TRUE ORDER BY full_name")
        lawyers = cursor.fetchall()

        cursor.execute("SELECT status_id, status_name FROM case_statuses")
        statuses = cursor.fetchall()

        cursor.execute("SELECT type_id, type_name FROM case_types")
        types = cursor.fetchall()

        cursor.execute("SELECT category_id, category_name FROM case_categories")
        categories = cursor.fetchall()

        if request.method == 'POST':
            client_id = request.form.get('client_id', type=int)
            lawyer_id = request.form.get('lawyer_id', type=int)
            status_id = request.form.get('status_id', type=int)
            type_id = request.form.get('type_id', type=int)
            category_id = request.form.get('category_id', type=int)
            description = request.form.get('description', '').strip()

            if not all([client_id, lawyer_id, status_id, type_id, category_id, description]):
                flash('Заполните все обязательные поля', 'danger')
                return render_template('case_form.html', mode='add',
                                       clients=clients, lawyers=lawyers,
                                       statuses=statuses, types=types, categories=categories)

            # Генерация номера дела
            cursor.execute("SELECT MAX(case_id) as max_id FROM cases")
            result = cursor.fetchone()
            new_case_id = (result['max_id'] or 0) + 1
            case_number = generate_case_number(type_id, new_case_id)

            # Вставка дела
            cursor.execute("""
                INSERT INTO cases 
                (case_number, client_id, lawyer_id, manager_id, status_id, type_id, category_id, description, open_date)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, CURRENT_DATE)
            """, (case_number, client_id, lawyer_id, session['user_id'], status_id, type_id, category_id, description))

            connection.commit()
            flash(f'Дело успешно создано. Номер: {case_number}', 'success')  # ✅ Внутри блока POST
            return redirect(url_for('cases'))  # ✅ Редирект после создания

        return render_template('case_form.html', mode='add',
                               clients=clients, lawyers=lawyers,
                               statuses=statuses, types=types, categories=categories)


@app.route('/cases/<int:case_id>/edit', methods=['GET', 'POST'])
def edit_case(case_id):
    """Редактирование дела"""
    if 'user_id' not in session or session['role_id'] not in [1, 2]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Загрузка данных для формы
        cursor.execute("SELECT client_id, full_name FROM clients ORDER BY full_name")
        clients = cursor.fetchall()

        cursor.execute("SELECT user_id, full_name FROM users WHERE role_id = 3 AND is_active = TRUE ORDER BY full_name")
        lawyers = cursor.fetchall()

        cursor.execute("SELECT status_id, status_name FROM case_statuses")
        statuses = cursor.fetchall()

        cursor.execute("SELECT type_id, type_name FROM case_types")
        types = cursor.fetchall()

        cursor.execute("SELECT category_id, category_name FROM case_categories")
        categories = cursor.fetchall()

        # Загрузка данных дела
        cursor.execute("SELECT * FROM cases WHERE case_id = %s", (case_id,))
        case = cursor.fetchone()

        if not case:
            flash('Дело не найдено', 'danger')
            return redirect(url_for('cases'))

        if request.method == 'POST':
            client_id = request.form.get('client_id', type=int)
            lawyer_id = request.form.get('lawyer_id', type=int)
            status_id = request.form.get('status_id', type=int)
            type_id = request.form.get('type_id', type=int)
            category_id = request.form.get('category_id', type=int)
            description = request.form.get('description', '').strip()

            if not all([client_id, lawyer_id, status_id, type_id, category_id, description]):
                flash('Заполните все обязательные поля', 'danger')
                return render_template('case_form.html', mode='edit', case=case,
                                       clients=clients, lawyers=lawyers,
                                       statuses=statuses, types=types, categories=categories)

            # Обновление дела
            cursor.execute("""
                UPDATE cases
                SET client_id = %s, lawyer_id = %s, status_id = %s, 
                    type_id = %s, category_id = %s, description = %s
                WHERE case_id = %s
            """, (client_id, lawyer_id, status_id, type_id, category_id, description, case_id))

            connection.commit()
            flash('Дело успешно обновлено', 'success')  # ✅ Внутри блока POST
            return redirect(url_for('cases'))  # ✅ Редирект после обновления

        return render_template('case_form.html', mode='edit', case=case,
                               clients=clients, lawyers=lawyers,
                               statuses=statuses, types=types, categories=categories)


@app.route('/cases/<int:case_id>/delete', methods=['POST'])
def delete_case(case_id):
    """Удаление дела"""
    if 'user_id' not in session or session['role_id'] not in [1]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Удаление дела (каскадно удалятся заседания, документы, комментарии)
        cursor.execute("DELETE FROM cases WHERE case_id = %s", (case_id,))
        connection.commit()

    flash('Дело успешно удалено', 'success')
    return redirect(url_for('cases'))


# ========== МАРШРУТЫ ЗАСЕДАНИЙ ==========

@app.route('/cases/<int:case_id>/hearings')
def case_hearings(case_id):
    """Список заседаний по делу"""
    if 'user_id' not in session:
        return redirect(url_for('login'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Информация о деле
        cursor.execute("""
            SELECT c.case_number, c.description,
                   cl.full_name AS client_name,
                   u.full_name AS lawyer_name
            FROM cases c
            JOIN clients cl ON c.client_id = cl.client_id
            JOIN users u ON c.lawyer_id = u.user_id
            WHERE c.case_id = %s
        """, (case_id,))
        case_info = cursor.fetchone()

        if not case_info:
            flash('Дело не найдено', 'danger')
            return redirect(url_for('cases'))

        # Список заседаний
        cursor.execute("""
            SELECT h.*, u.full_name AS creator_name
            FROM hearings h
            JOIN users u ON h.created_by = u.user_id
            WHERE h.case_id = %s
            ORDER BY h.hearing_date DESC
        """, (case_id,))
        hearings = cursor.fetchall()

    return render_template('hearings.html',
                           case_id=case_id,
                           case_info=case_info,
                           hearings=hearings,
                           role_id=session['role_id'])


@app.route('/cases/<int:case_id>/hearings/new', methods=['GET', 'POST'])
def add_hearing(case_id):
    """Добавление заседания"""
    if 'user_id' not in session or session['role_id'] not in [1, 2, 3]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('case_hearings', case_id=case_id))

    connection = get_db()
    with connection.cursor() as cursor:
        cursor.execute("SELECT case_number FROM cases WHERE case_id = %s", (case_id,))
        case = cursor.fetchone()

        if not case:
            flash('Дело не найдено', 'danger')
            return redirect(url_for('cases'))

        if request.method == 'POST':
            hearing_date = request.form.get('hearing_date')
            court_name = request.form.get('court_name', '').strip()
            courtroom = request.form.get('courtroom', '').strip()
            result = request.form.get('result', '').strip()

            if not all([hearing_date, court_name]):
                flash('Заполните обязательные поля', 'danger')
                return render_template('hearing_form.html', mode='add', case_id=case_id,
                                       case_number=case['case_number'])

            # Вставка заседания
            cursor.execute("""
                INSERT INTO hearings (case_id, hearing_date, court_name, courtroom, result, created_by)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (case_id, hearing_date, court_name, courtroom if courtroom else None, result if result else None,
                  session['user_id']))

            connection.commit()
            flash('Заседание успешно добавлено', 'success')
            return redirect(url_for('case_hearings', case_id=case_id))  # ✅ Редирект после добавления

        return render_template('hearing_form.html', mode='add', case_id=case_id, case_number=case['case_number'])


@app.route('/hearings/<int:hearing_id>/edit', methods=['GET', 'POST'])
def edit_hearing(hearing_id):
    """Редактирование заседания"""
    if 'user_id' not in session or session['role_id'] not in [1, 2, 3]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Загрузка данных заседания
        cursor.execute("""
            SELECT h.*, c.case_number, c.case_id
            FROM hearings h
            JOIN cases c ON h.case_id = c.case_id
            WHERE h.hearing_id = %s
        """, (hearing_id,))
        hearing = cursor.fetchone()

        if not hearing:
            flash('Заседание не найдено', 'danger')
            return redirect(url_for('cases'))

        if request.method == 'POST':
            hearing_date = request.form.get('hearing_date')
            court_name = request.form.get('court_name', '').strip()
            courtroom = request.form.get('courtroom', '').strip()
            result = request.form.get('result', '').strip()

            if not all([hearing_date, court_name]):
                flash('Заполните обязательные поля', 'danger')
                return render_template('hearing_form.html', mode='edit',
                                       hearing=hearing, case_id=hearing['case_id'])

            # Обновление заседания
            cursor.execute("""
                UPDATE hearings
                SET hearing_date = %s, court_name = %s, courtroom = %s, result = %s
                WHERE hearing_id = %s
            """, (hearing_date, court_name, courtroom if courtroom else None,
                  result if result else None, hearing_id))

            connection.commit()
            flash('Заседание успешно обновлено', 'success')
            return redirect(url_for('case_hearings', case_id=hearing['case_id']))

        return render_template('hearing_form.html', mode='edit',
                               hearing=hearing, case_id=hearing['case_id'])


@app.route('/hearings/<int:hearing_id>/delete', methods=['POST'])
def delete_hearing(hearing_id):
    """Удаление заседания"""
    if 'user_id' not in session or session['role_id'] not in [1, 2, 3]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Получение case_id для редиректа
        cursor.execute("SELECT case_id FROM hearings WHERE hearing_id = %s", (hearing_id,))
        result = cursor.fetchone()

        if not result:
            flash('Заседание не найдено', 'danger')
            return redirect(url_for('cases'))

        case_id = result['case_id']

        # Удаление заседания
        cursor.execute("DELETE FROM hearings WHERE hearing_id = %s", (hearing_id,))
        connection.commit()

        flash('Заседание успешно удалено', 'success')
        return redirect(url_for('case_hearings', case_id=case_id))


# ========== МАРШРУТЫ ДОКУМЕНТОВ ==========

@app.route('/cases/<int:case_id>/documents')
def case_documents(case_id):
    """Список документов по делу"""
    if 'user_id' not in session:
        return redirect(url_for('login'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Информация о деле
        cursor.execute("""
            SELECT c.case_number, c.description,
                   cl.full_name AS client_name
            FROM cases c
            JOIN clients cl ON c.client_id = cl.client_id
            WHERE c.case_id = %s
        """, (case_id,))
        case_info = cursor.fetchone()

        if not case_info:
            flash('Дело не найдено', 'danger')
            return redirect(url_for('cases'))

        # Список документов
        cursor.execute("""
            SELECT d.*, dt.type_name, u.full_name AS uploader_name
            FROM documents d
            JOIN document_types dt ON d.type_id = dt.type_id
            JOIN users u ON d.uploaded_by = u.user_id
            WHERE d.case_id = %s
            ORDER BY d.upload_date DESC
        """, (case_id,))
        documents = cursor.fetchall()

        # Типы документов для формы загрузки
        cursor.execute("SELECT type_id, type_name FROM document_types")
        doc_types = cursor.fetchall()

    return render_template('documents.html',
                           case_id=case_id,
                           case_info=case_info,
                           documents=documents,
                           doc_types=doc_types,
                           role_id=session['role_id'])


@app.route('/cases/<int:case_id>/documents/upload', methods=['POST'])
def upload_document(case_id):
    """Загрузка документа"""
    if 'user_id' not in session or session['role_id'] not in [1, 2, 3]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('case_documents', case_id=case_id))

    document_name = request.form.get('document_name', '').strip()
    type_id = request.form.get('type_id', type=int)

    if not all([document_name, type_id]):
        flash('Заполните все поля', 'danger')
        return redirect(url_for('case_documents', case_id=case_id))

    # Здесь должна быть логика загрузки файла
    # Для примера используем заглушку
    file_path = f"/uploads/case_{case_id}/document_{datetime.now().timestamp()}.pdf"

    connection = get_db()
    with connection.cursor() as cursor:
        cursor.execute("""
            INSERT INTO documents (case_id, type_id, document_name, file_path, uploaded_by)
            VALUES (%s, %s, %s, %s, %s)
        """, (case_id, type_id, document_name, file_path, session['user_id']))

        connection.commit()

    flash('Документ успешно загружен', 'success')
    return redirect(url_for('case_documents', case_id=case_id))


@app.route('/documents/<int:document_id>/delete', methods=['POST'])
def delete_document(document_id):
    """Удаление документа"""
    if 'user_id' not in session or session['role_id'] not in [1, 2, 3]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Получение case_id для редиректа
        cursor.execute("SELECT case_id FROM documents WHERE document_id = %s", (document_id,))
        result = cursor.fetchone()

        if not result:
            flash('Документ не найден', 'danger')
            return redirect(url_for('cases'))

        case_id = result['case_id']

        # Удаление документа
        cursor.execute("DELETE FROM documents WHERE document_id = %s", (document_id,))
        connection.commit()

    flash('Документ успешно удалён', 'success')
    return redirect(url_for('case_documents', case_id=case_id))


# ========== МАРШРУТЫ КОММЕНТАРИЕВ ==========

@app.route('/cases/<int:case_id>/comments', methods=['POST'])
def add_comment(case_id):
    """Добавление комментария к делу"""
    if 'user_id' not in session:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('cases'))

    comment_text = request.form.get('comment_text', '').strip()

    if not comment_text:
        flash('Введите текст комментария', 'danger')
        return redirect(url_for('cases'))

    connection = get_db()
    with connection.cursor() as cursor:
        cursor.execute("""
            INSERT INTO comments (case_id, user_id, comment_text)
            VALUES (%s, %s, %s)
        """, (case_id, session['user_id'], comment_text))

        connection.commit()

    flash('Комментарий добавлен', 'success')
    return redirect(url_for('cases'))


# ========== МАРШРУТЫ ОТЧЕТОВ ==========

@app.route('/reports')
def reports():
    """Страница отчетов"""
    if 'user_id' not in session or session['role_id'] not in [1, 2]:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('dashboard'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Отчет по загруженности юристов
        cursor.execute("""
            SELECT 
                u.user_id,
                u.full_name AS lawyer_name,
                COUNT(c.case_id) AS total_cases,
                SUM(CASE WHEN c.status_id = 2 THEN 1 ELSE 0 END) AS in_progress_cases,
                SUM(CASE WHEN c.status_id = 4 THEN 1 ELSE 0 END) AS completed_cases,
                AVG(DATEDIFF(CURDATE(), c.open_date)) AS avg_days_open
            FROM users u
            LEFT JOIN cases c ON u.user_id = c.lawyer_id AND u.role_id = 3
            WHERE u.is_active = TRUE
            GROUP BY u.user_id, u.full_name
            ORDER BY total_cases DESC
        """)
        lawyer_stats = cursor.fetchall()

        # Статистика по статусам дел
        cursor.execute("""
            SELECT 
                cs.status_name,
                COUNT(c.case_id) AS count
            FROM case_statuses cs
            LEFT JOIN cases c ON cs.status_id = c.status_id
            GROUP BY cs.status_id, cs.status_name
            ORDER BY cs.status_id
        """)
        status_stats = cursor.fetchall()

    # Экспорт в CSV
    export_format = request.args.get('export')
    if export_format == 'csv':
        return export_lawyer_report_csv(lawyer_stats)

    return render_template('reports.html',
                           lawyer_stats=lawyer_stats,
                           status_stats=status_stats,
                           role_id=session['role_id'])


def export_lawyer_report_csv(data):
    """Экспорт отчёта по юристам в CSV"""
    output = StringIO()
    writer = csv.writer(output, delimiter=';', quoting=csv.QUOTE_MINIMAL)

    # Заголовки
    writer.writerow(['Отчёт по загруженности юристов'])
    writer.writerow(['Дата формирования:', datetime.now().strftime('%d.%m.%Y %H:%M')])
    writer.writerow([])
    writer.writerow(['№', 'Юрист', 'Всего дел', 'В работе', 'Завершено', 'Средний срок (дни)'])

    # Данные
    for idx, row in enumerate(data, 1):
        avg_days = row['avg_days_open']
        avg_days_str = f"{float(avg_days):.1f}" if avg_days else '-'
        writer.writerow([
            idx,
            row['lawyer_name'],
            row['total_cases'],
            row['in_progress_cases'],
            row['completed_cases'],
            avg_days_str
        ])

    # Итог
    writer.writerow([])
    writer.writerow(['ИТОГО', '', sum(r['total_cases'] for r in data),
                     sum(r['in_progress_cases'] for r in data),
                     sum(r['completed_cases'] for r in data), ''])

    output.seek(0)

    # Создание ответа
    response = make_response(output.getvalue())
    response.headers[
        'Content-Disposition'] = f'attachment; filename=lawyer_report_{datetime.now().strftime("%Y%m%d_%H%M")}.csv'
    response.headers['Content-Type'] = 'text/csv; charset=utf-8-sig'

    return response


# ========== МАРШРУТЫ ПОЛЬЗОВАТЕЛЕЙ ==========

@app.route('/users')
def users():
    """Список пользователей"""
    if 'user_id' not in session or session['role_id'] != 1:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('dashboard'))

    connection = get_db()
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT u.*, r.role_name,
                   (SELECT COUNT(*) FROM cases WHERE lawyer_id = u.user_id) AS cases_count
            FROM users u
            JOIN user_roles r ON u.role_id = r.role_id
            ORDER BY u.created_at DESC
        """)
        users_list = cursor.fetchall()

    return render_template('users.html', users=users_list, role_id=session['role_id'])


@app.route('/users/new', methods=['GET', 'POST'])
def add_user():
    """Добавление пользователя"""
    if 'user_id' not in session or session['role_id'] != 1:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('users'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Загрузка ролей (без администратора для обычных админов)
        if session['user_id'] == 1:  # Только супер-админ может создавать админов
            cursor.execute("SELECT role_id, role_name FROM user_roles")
        else:
            cursor.execute(
                "SELECT role_id, role_name FROM user_roles WHERE role_id != 1")  # Исключаем роль администратора

        roles = cursor.fetchall()

        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            password = request.form.get('password', '').strip()
            role_id = request.form.get('role_id', type=int)
            full_name = request.form.get('full_name', '').strip()
            email = request.form.get('email', '').strip()

            if not all([username, password, role_id, full_name]):
                flash('Заполните все обязательные поля', 'danger')
                return render_template('user_form.html', mode='add', roles=roles)

            # Проверка: обычный админ не может создавать админов
            if role_id == 1 and session['user_id'] != 1:
                flash('Только супер-администратор может создавать администраторов', 'danger')
                return render_template('user_form.html', mode='add', roles=roles,
                                       username=username, full_name=full_name, email=email)

            # Проверка уникальности логина
            cursor.execute("SELECT user_id FROM users WHERE username = %s", (username,))
            if cursor.fetchone():
                flash(f'Пользователь с логином {username} уже существует', 'warning')
                return render_template('user_form.html', mode='add', roles=roles,
                                       username=username, full_name=full_name, email=email)

            # Хеширование пароля
            password_hash = generate_password_hash(password, method='pbkdf2:sha256')

            # Вставка пользователя
            cursor.execute("""
                INSERT INTO users (username, password_hash, role_id, full_name, email, is_active)
                VALUES (%s, %s, %s, %s, %s, TRUE)
            """, (username, password_hash, role_id, full_name, email if email else None))

            connection.commit()
            flash('Пользователь успешно добавлен', 'success')
            return redirect(url_for('users'))

        return render_template('user_form.html', mode='add', roles=roles)


@app.route('/users/<int:user_id>/edit', methods=['GET', 'POST'])
def edit_user(user_id):
    """Редактирование пользователя"""
    if 'user_id' not in session or session['role_id'] != 1:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('users'))

    # Запрет редактирования себя
    if user_id == session['user_id']:
        flash('Вы не можете редактировать свою учётную запись', 'danger')
        return redirect(url_for('users'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Загрузка ролей (без администратора для обычных админов)
        if session['user_id'] == 1:  # Только супер-админ может редактировать админов
            cursor.execute("SELECT role_id, role_name FROM user_roles")
        else:
            cursor.execute("SELECT role_id, role_name FROM user_roles WHERE role_id != 1")

        roles = cursor.fetchall()

        # Загрузка данных пользователя
        cursor.execute("SELECT * FROM users WHERE user_id = %s", (user_id,))
        user = cursor.fetchone()

        if not user:
            flash('Пользователь не найден', 'danger')
            return redirect(url_for('users'))

        # Запрет редактирования других администраторов для обычных админов
        if user['role_id'] == 1 and session['user_id'] != 1:
            flash('Только супер-администратор может редактировать администраторов', 'danger')
            return redirect(url_for('users'))

        if request.method == 'POST':
            username = request.form.get('username', '').strip()
            role_id = request.form.get('role_id', type=int)
            full_name = request.form.get('full_name', '').strip()
            email = request.form.get('email', '').strip()
            is_active = request.form.get('is_active') == 'on'

            if not all([username, role_id, full_name]):
                flash('Заполните все обязательные поля', 'danger')
                return render_template('user_form.html', mode='edit', user=user, roles=roles)

            # Проверка: обычный админ не может назначать админов
            if role_id == 1 and session['user_id'] != 1:
                flash('Только супер-администратор может назначать администраторов', 'danger')
                return render_template('user_form.html', mode='edit', user=user, roles=roles)

            # Проверка уникальности логина (кроме текущего пользователя)
            cursor.execute("SELECT user_id FROM users WHERE username = %s AND user_id != %s",
                           (username, user_id))
            if cursor.fetchone():
                flash(f'Пользователь с логином {username} уже существует', 'warning')
                return render_template('user_form.html', mode='edit', user=user, roles=roles)

            # Обновление пользователя
            cursor.execute("""
                UPDATE users
                SET username = %s, role_id = %s, full_name = %s, email = %s, is_active = %s
                WHERE user_id = %s
            """, (username, role_id, full_name, email if email else None, is_active, user_id))

            connection.commit()
            flash('Пользователь успешно обновлён', 'success')
            return redirect(url_for('users'))

        return render_template('user_form.html', mode='edit', user=user, roles=roles)


@app.route('/users/<int:user_id>/delete', methods=['POST'])
def delete_user(user_id):
    """Удаление пользователя"""
    if 'user_id' not in session or session['role_id'] != 1:
        flash('Нет прав доступа', 'danger')
        return redirect(url_for('users'))

    # Запрет удаления себя
    if user_id == session['user_id']:
        flash('Вы не можете удалить свою учётную запись', 'danger')
        return redirect(url_for('users'))

    connection = get_db()
    with connection.cursor() as cursor:
        # Проверка: нельзя удалять администраторов (кроме супер-админа)
        cursor.execute("SELECT role_id FROM users WHERE user_id = %s", (user_id,))
        user = cursor.fetchone()

        if user and user['role_id'] == 1 and session['user_id'] != 1:
            flash('Только супер-администратор может удалять администраторов', 'danger')
            return redirect(url_for('users'))

        # Проверка наличия связанных записей
        cursor.execute("SELECT COUNT(*) as count FROM cases WHERE lawyer_id = %s OR manager_id = %s",
                       (user_id, user_id))
        result = cursor.fetchone()

        if result['count'] > 0:
            flash(f'Нельзя удалить пользователя, у которого есть {result["count"]} связанных дел', 'danger')
            return redirect(url_for('users'))

        # Удаление пользователя
        cursor.execute("DELETE FROM users WHERE user_id = %s", (user_id,))
        connection.commit()

        flash('Пользователь успешно удалён', 'success')
        return redirect(url_for('users'))


# ========== ЗАПУСК ПРИЛОЖЕНИЯ ==========

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)