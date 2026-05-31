# 🎓 EduVerso

EduVerso is an AI-enhanced voice-interactive microlearning application designed for students. It combines adaptive learning, gamification, artificial intelligence, voice-based interaction, and peer collaboration to create a more engaging and personalized learning experience.

The platform allows students to learn through structured microlearning modules, complete AI-generated quizzes, answer questions using voice interaction, participate in learning missions, and receive feedback from peers. EduVerso aims to improve student engagement, knowledge retention, and active participation while making learning more interactive and accessible.

---

# 🚀 What EduVerso Does

EduVerso transforms traditional learning into an interactive digital experience by combining educational content, artificial intelligence, and gamification within a single platform.

Students can access learning modules, complete quizzes, participate in voice-based activities, earn rewards through missions, track their progress, and collaborate with peers through feedback and discussion features. The application is designed to support self-paced learning while encouraging continuous engagement and knowledge development.

The platform focuses on creating a learner-centered environment where students can develop skills, reinforce concepts, and stay motivated through interactive learning experiences.

---

# ✨ Core Features

### 🤖 AI-Powered Quiz Generation

Generates adaptive quizzes based on student performance and learning progress.

### 🎤 Voice-Interactive Learning

Allows students to answer questions verbally and interact naturally with educational content.

### 🎮 Gamified Learning Experience

Complete missions, earn rewards, unlock achievements, and progress through educational challenges.

### 📚 Microlearning Modules

Lessons are divided into smaller learning units to improve comprehension and retention.

### 👥 Peer Feedback System

Students can share explanations, receive ratings, and provide constructive feedback to peers.

### 📈 Progress Tracking

Track completed lessons, quiz performance, achievements, and learning milestones.

### 📢 Announcements

Receive important updates, reminders, and academic notifications within the platform.

---

# 🏗️ Architecture Overview

EduVerso follows a client-server architecture designed to support scalable and interactive learning experiences.

The mobile application serves as the primary interface for students and communicates with backend services through REST APIs. Learning data, user information, quiz results, and application content are stored using MySQL and Supabase services. Authentication is managed through Firebase Authentication, while AI-powered services support adaptive learning and intelligent quiz generation.

```text
Flutter Mobile Application
            │
            ▼
      Node.js API
            │
    ┌───────┴───────┐
    ▼               ▼
  MySQL         Supabase
            │
            ▼
      AI Services
            │
            ▼
 Firebase Authentication
```

---

# 💻 Technology Stack

## 🎨 Frontend

* Flutter
* Dart
* React
* TypeScript

## ⚙️ Backend

* Node.js
* Express.js
* MySQL
* Supabase

## 🧠 Smart Services

* Firebase Authentication
* Artificial Intelligence Integration
* Speech Recognition

---

# 📋 Requirements

Before running EduVerso, ensure the following are installed:

* Flutter SDK
* Dart SDK
* Node.js
* npm
* MySQL
* Supabase Project
* Firebase Project
* Git

---

# 🔧 Environment Setup

Create an environment configuration file:

```env
PORT=5002

DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=eduv_backend

SUPABASE_URL=your_supabase_url
SUPABASE_KEY=your_supabase_key

FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_PROJECT_ID=your_project_id
```

Important values:

* **DB_HOST** – MySQL database host
* **DB_NAME** – EduVerso database name
* **SUPABASE_URL** – Supabase project URL
* **SUPABASE_KEY** – Supabase API key
* **FIREBASE_API_KEY** – Firebase API key
* **FIREBASE_PROJECT_ID** – Firebase project identifier

---

# ⚡ Installation

Clone the repository:

```bash
git clone https://github.com/yourusername/eduverso.git
```

Install backend dependencies:

```bash
npm install
```

Start the backend server:

```bash
npm start
```

Run the Flutter application:

```bash
flutter pub get
flutter run
```

---

# 📂 Project Structure

```text
EduVerso
│
├── frontend
│   ├── screens
│   ├── widgets
│   ├── services
│   └── models
│
├── backend
│   ├── routes
│   ├── controllers
│   ├── middleware
│   ├── services
│   └── database
│
├── assets
│
└── documentation
```

---

# 🔒 Data Privacy & Security

EduVerso follows the principles of the Philippine Data Privacy Act of 2012 (RA 10173).

Security measures include:

* 🔐 Firebase Authentication
* 🛡️ Secure API Communication
* 👤 Role-Based Access Control
* 🔒 Protected Student Information
* ☁️ Secure Cloud Data Storage

The platform is designed to ensure the confidentiality, integrity, and security of student learning data.
