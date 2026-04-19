# EduVerso Backend Starter (Node.js + MySQL)

This is a starter backend project for your EduVerso app using:

- Node.js
- Express
- MySQL
- JWT
- bcrypt

## 1. Install packages

```bash
npm install
```

## 2. Create your environment file

Copy `.env.example` and rename it to `.env`.

Example:

```env
PORT=5000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=eduverso_db
JWT_SECRET=change_this_to_a_long_random_secret
JWT_EXPIRES_IN=7d
```

## 3. Create the MySQL database

Open MySQL and run:

```sql
sql/eduverso_db.sql
```

Or paste the SQL inside your MySQL client.

## 4. Start the server

```bash
npm run dev
```

If successful, you should see:

```bash
MySQL connected successfully.
Server running on http://localhost:5000
```

## API Routes

### Register
**POST** `/api/auth/register`

```json
{
  "fullName": "Juan Dela Cruz",
  "email": "juan@example.com",
  "password": "password123"
}
```

### Login
**POST** `/api/auth/login`

```json
{
  "email": "juan@example.com",
  "password": "password123"
}
```

### Profile
**GET** `/api/auth/profile`

Headers:

```text
Authorization: Bearer YOUR_TOKEN_HERE
```

## Test in Postman

### Register
- Method: POST
- URL: `http://localhost:5000/api/auth/register`

### Login
- Method: POST
- URL: `http://localhost:5000/api/auth/login`

## Deploy later on Railway

When you are ready to deploy:
1. Push this backend to GitHub
2. Create a Railway project
3. Add your environment variables in Railway
4. Connect your database
5. Replace local API URL in Flutter with your Railway URL

## Connect to Flutter later

For your Flutter app:
- Chrome/Web local test: `http://localhost:5000`
- Android emulator local test: `http://10.0.2.2:5000`
- Real phone local test: use your computer's local IP

## Recommended next step

After backend works, connect your `login_page.dart` and `register_page.dart` to:
- `/api/auth/login`
- `/api/auth/register`
