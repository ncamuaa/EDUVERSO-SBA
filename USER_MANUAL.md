# EduVerso User Manual

## About EduVerso
EduVerso is a digital learning platform built to support student engagement and academic growth. This repository contains:
- a Flutter-based Student Mobile App (`eduv_student_separated`)
- a Node.js + MySQL Backend API (`eduv_backend_mysql`)

> Note: Although the root project overview mentions an admin dashboard, the current workspace includes only the mobile student app and the backend API.

## Who should use this manual
- Students using the EduVerso app
- Developers setting up the app locally
- Teachers or support staff who need a quick orientation to the system

---

## 1. System Requirements
### Student app
- Flutter SDK
- Android Studio or Xcode (for mobile emulators)
- Device or emulator for testing

### Backend
- Node.js (recommended version 16+)
- npm
- MySQL server

---

## 2. Backend Setup
The backend code is located in `eduv_backend_mysql`.

### 2.1 Install dependencies
From the backend folder:
```bash
cd eduv_backend_mysql
npm install
```

### 2.2 Configure environment
Create a `.env` file from `.env.example` and set your database and JWT settings.
Example values:
```env
PORT=5000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=eduverso_db
JWT_SECRET=your_secret_key
JWT_EXPIRES_IN=7d
```

### 2.3 Create the database
Import or run the SQL script located at `eduv_backend_mysql/sql/eduverso_db.sql` in your MySQL instance.

### 2.4 Start the backend
```bash
npm run dev
```

Expected success output:
- `MySQL connected successfully.`
- `Server running on http://localhost:5000`

---

## 3. Student App Setup
The student app is in `eduv_student_separated`.

### 3.1 Install Flutter dependencies
```bash
cd eduv_student_separated
flutter pub get
```

### 3.2 Run the app
```bash
flutter run
```

### 3.3 Build an APK
```bash
flutter build apk
```

### 3.4 Local API connection
When testing on Android emulators, use the correct local host mapping:
- Android emulator: `http://10.0.2.2:5000`
- iOS simulator: `http://localhost:5000`
- Real device: use your computer’s local IP address and ensure the backend is accessible on the same network.

---

## 4. User Flow: Student App
This section explains the student-facing screens and features.

### 4.1 Login / Register
- Register a new account using name, email, and password.
- Login with the registered email and password.
- After login, the app stores your session token and allows secure access to protected features.

### 4.2 Dashboard
- Serves as the main entry screen after login.
- Displays quick access to learning modules, AI tutor, announcements, feedback, and game arena.

### 4.3 Modules
- Browse learning modules available to the student.
- Each module may include lessons or learning content.
- Use this section to study topics assigned within the platform.

### 4.4 AI Tutor
- Access AI-powered tutoring assistance.
- Ask questions or review explanations to improve understanding.
- This feature is designed to support personalized learning.

### 4.5 Feedback
- Submit feedback about the app, lessons, or learning experience.
- Feedback helps administrators identify issues and improve the system.

### 4.6 Announcements
- View announcements from teachers or platform administrators.
- Stay informed about upcoming events, updates, or important notices.

### 4.7 Game Arena
- Access gamified learning activities and challenges.
- This area is intended to make learning more engaging.

### 4.8 Profile and Settings
- Update user profile details and account settings.
- Manage personal preferences if the app exposes options in the settings page.

---

## 5. API Guide
The backend exposes several routes to support user authentication and core data.

### 5.1 Authentication routes
- `POST /api/auth/register` - create a new user account.
- `POST /api/auth/login` - authenticate and receive a JWT.
- `GET /api/auth/profile` - retrieve profile details (requires `Authorization: Bearer TOKEN`).

### 5.2 Common request example
Login payload:
```json
{
  "email": "juan@example.com",
  "password": "password123"
}
```

Authorization header example:
```text
Authorization: Bearer YOUR_TOKEN_HERE
```

---

## 6. Troubleshooting
### Backend issues
- `MySQL connected successfully.` not shown: verify MySQL is running, `.env` values are correct, and the database exists.
- `PORT` in `.env` conflict: choose a different port and restart.

### Flutter issues
- `flutter pub get` fails: ensure Flutter SDK is installed and path is configured.
- Unable to reach backend from emulator: use `10.0.2.2` for Android or your machine’s IP for physical devices.

### Login problems
- Invalid credentials: verify email and password or register again.
- Token authorization errors: restart the app and login again to refresh the session.

---

## 7. Notes for Developers
- Backend source files are under `eduv_backend_mysql/`.
- Flutter source files are under `eduv_student_separated/lib/`.
- The backend uses Express, JWT, bcrypt, and MySQL.
- The Flutter app includes pages for login, dashboard, modules, AI tutor, feedback, announcements, profile, settings, and game arena.

## 8. Next Steps
- Connect the Flutter app’s login and registration screens to the backend auth endpoints.
- Expand the admin dashboard if you want a complete admin management interface.
- Add detailed content and lesson flows for modules and the AI tutor.

---

## Contact and Support
For support building or extending EduVerso, review the code files in `eduv_backend_mysql` and `eduv_student_separated`, then update configuration and API connections as needed.
