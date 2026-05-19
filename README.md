# 🚀 ASTU-Q — Peer-to-Peer Doubt Solver Platform

> A modern student collaboration platform designed to help learners ask questions, share knowledge, compete on leaderboards, and learn together in real time.

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![PHP](https://img.shields.io/badge/PHP-8.x-777BB4?logo=php)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange?logo=mysql)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Active-success)

---

# 📚 Overview

**ASTU-Q** is a mobile-based peer-to-peer academic assistance platform developed for students to collaborate, solve academic problems, and build a strong learning community.

The application enables users to:

* ❓ Ask academic questions
* 💡 Receive answers from peers
* 🏆 Earn points and climb leaderboards
* 💬 Chat with other students in real time
* 📈 Track achievements and activity
* 🔔 Receive instant notifications
* 🛠️ Manage content through an admin dashboard

The project follows modern software engineering practices including:

* Clean Architecture
* RESTful APIs
* Secure Authentication
* Responsive UI/UX
* Scalable Backend Design

---

# 🎯 Project Goals

The primary goal of ASTU-Q is to create a collaborative educational environment where students can:

* Learn from one another
* Solve academic challenges faster
* Encourage knowledge sharing
* Improve communication among students
* Build a competitive and engaging learning ecosystem

---

# 🏗️ System Architecture

```text
┌───────────────────────┐
│   Flutter Mobile App  │
└──────────┬────────────┘
           │ REST API
           ▼
┌───────────────────────┐
│      PHP Backend      │
│  Authentication APIs  │
│  Question Services    │
│  Chat Services        │
│  Leaderboard Engine   │
└──────────┬────────────┘
           ▼
┌───────────────────────┐
│     MySQL Database    │
└───────────────────────┘
```

---

# ✨ Core Features

## 🔐 Authentication System

* User Registration
* Secure Login
* JWT Authentication
* Password Recovery
* Session Management
* Profile Management

---

## ❓ Question & Answer System

* Create academic questions
* Add images to questions
* Subject categorization
* Answer questions
* Upvote & downvote answers
* Mark best answers
* Search & filter questions

---

## 🏆 Leaderboard System

* Global ranking system
* Weekly / Monthly / All-time rankings
* Achievement badges
* User levels & points
* Activity tracking

---

## 💬 Real-Time Chat

* Direct messaging
* Group discussions
* Message status indicators
* Student collaboration support

---

## 🔔 Notification System

* Answer notifications
* Achievement alerts
* System announcements
* Activity updates

---

## 👤 Profile Management

* User profiles
* Avatar upload
* Bio & activity history
* Statistics tracking

---

## 🛡️ Admin Dashboard

* User management
* Content moderation
* Analytics dashboard
* Reports & monitoring

---

# 📱 User Roles

| Role            | Description                       |
| --------------- | --------------------------------- |
| 👨‍🎓 Student   | Ask questions, answer, vote, chat |
| ⭐ Verified User | Trusted contributors with badges  |
| 🛠️ Admin       | Full system control & moderation  |

---

# 🧰 Technology Stack

## 🎨 Frontend

| Technology        | Purpose              |
| ----------------- | -------------------- |
| Flutter 3.x       | Mobile App Framework |
| Dart              | Programming Language |
| Provider          | State Management     |
| Dio               | API Communication    |
| GetIt             | Dependency Injection |
| SharedPreferences | Local Storage        |

---

## ⚙️ Backend

| Technology   | Purpose        |
| ------------ | -------------- |
| PHP 8.x      | Backend API    |
| MySQL 8.0    | Database       |
| JWT          | Authentication |
| Apache/Nginx | Web Server     |

---

## ☁️ Services & Tools

| Tool       | Usage                     |
| ---------- | ------------------------- |
| Firebase   | Notifications & Analytics |
| Git        | Version Control           |
| Postman    | API Testing               |
| phpMyAdmin | Database Management       |

---

# 📂 Project Structure

```bash
astu-q/
│
├── mobile_app/
│   ├── lib/
│   ├── assets/
│   ├── screens/
│   ├── widgets/
│   └── services/
│
├── backend/
│   ├── api/
│   ├── auth/
│   ├── uploads/
│   ├── config/
│   └── database/
│
├── admin_dashboard/
│
├── database/
│   └── astuq_database.sql
│
└── README.md
```

---

# 🗄️ Database Design

## Core Tables

* `users`
* `questions`
* `answers`
* `roles`
* `user_roles`
* `notifications`

### Database Features

* Relational schema design
* Indexed queries
* Secure data handling
* Transaction support
* Optimized performance

---

# 🔌 API Overview

## Authentication APIs

```http
POST /login.php
POST /signup.php
POST /auth/logout
POST /auth/forgot-password
```

---

## Question APIs

```http
POST /create_question.php
GET  /get_questions.php
GET  /get_question.php
PUT  /questions
DELETE /questions
```

---

## Answer APIs

```http
POST /answers
POST /answers/vote
POST /answers/best
```

---

## Leaderboard APIs

```http
GET /leaderboard.php
GET /get_user_rank.php
GET /leaderboard_stats.php
```

---

# 🔒 Security Features

The system follows modern security standards including:

* ✅ JWT Authentication
* ✅ Password Hashing (bcrypt)
* ✅ HTTPS Encryption
* ✅ SQL Injection Prevention
* ✅ Input Validation
* ✅ Rate Limiting
* ✅ Secure File Upload Validation
* ✅ OWASP Mobile Security Guidelines

---

# ⚡ Performance Requirements

| Feature             | Target       |
| ------------------- | ------------ |
| App Launch Time     | < 3 seconds  |
| API Response Time   | < 2 seconds  |
| Database Query Time | < 500ms      |
| Concurrent Users    | 1000+        |
| Image Upload        | < 10 seconds |

---

# 🧪 Testing Strategy

The project includes multiple testing approaches:

* ✅ Unit Testing
* ✅ Integration Testing
* ✅ UI Testing
* ✅ Performance Testing
* ✅ Security Testing

---

# 🚀 Development Roadmap

## Phase 1 — Project Setup

* Environment configuration
* Architecture setup
* Database design

## Phase 2 — Core Development

* Authentication
* Question & Answer system
* Profile management

## Phase 3 — Advanced Features

* Leaderboards
* Chat system
* Notifications

## Phase 4 — Admin Dashboard

* Moderation tools
* Analytics system

## Phase 5 — Testing & QA

* Bug fixing
* Security audit
* Performance optimization

## Phase 6 — Deployment

* Production deployment
* App publishing
* CI/CD setup

---

# 📡 Deployment Environment

## Development

* Local PHP Server
* Local MySQL Database

## Staging

* Staging API Server
* Test Database

## Production

* Cloud Hosting
* Load Balancer
* CDN Support
* Backup Systems

---

# 🌍 Platform Support

| Platform     | Supported       |
| ------------ | --------------- |
| Android      | ✅               |
| iOS          | ✅               |
| Tablets      | ✅               |
| Offline Mode | Partial Support |

---

# 📖 Future Enhancements

* 🌐 Amharic Language Support
* 🤖 AI-Powered Answer Suggestions
* 📹 Video-Based Explanations
* 🧠 Smart Recommendation System
* 📊 Advanced Analytics Dashboard
* 🎓 Course-Based Communities

---

# 👨‍💻 Development Team

**Project:** ASTU-Q Mobile Application
**Version:** 1.0
**Release Date:** May 2026

Developed with ❤️ to empower collaborative learning among students.

---

# 📜 License

This project is licensed under the MIT License.

```text
MIT License © 2026 ASTU-Q Development Team
```

---

# ⭐ Support the Project

If you like this project:

* 🌟 Star the repository
* 🍴 Fork the project
* 🛠️ Contribute improvements
* 📢 Share with others

---

# 📬 Contact

For support, suggestions, or collaboration:

📧 Email: [samueleva3949@gmail.com](mailto:your-email@example.com)
🌐 Website: [evadevstudio.com](https://evadevstudio.com?utm_source=chatgpt.com)

---

# 🎓 “Learn Together, Grow Together.”

## ASTU-Q — Empowering Students Through Collaboration 🚀
