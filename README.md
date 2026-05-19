SOFTWARE REQUIREMENTS SPECIFICATION (SRS)
FOR ASTU-Q PEER-TO-PEER DOUBT SOLVER APPLICATION

Document Version: 1.0
Date: May 2026
Author: Development Team
Project: ASTU-Q Mobile Application

========================================================================
TABLE OF CONTENTS
========================================================================

1. INTRODUCTION
   1.1 Purpose
   1.2 Scope
   1.3 Definitions, Acronyms, and Abbreviations
   1.4 References
   1.5 Overview

2. OVERALL DESCRIPTION
   2.1 Product Perspective
   2.2 Product Functions
   2.3 User Classes and Characteristics
   2.4 Operating Environment
   2.5 Design and Implementation Constraints
   2.6 Assumptions and Dependencies

3. SYSTEM FEATURES
   3.1 User Authentication Module
   3.2 Question and Answer Module
   3.3 Leaderboard Module
   3.4 Chat Module
   3.5 Profile Management Module
   3.6 Notification Module
   3.7 Admin Dashboard Module

4. EXTERNAL INTERFACE REQUIREMENTS
   4.1 User Interfaces
   4.2 Hardware Interfaces
   4.3 Software Interfaces
   4.4 Communications Interfaces

5. NON-FUNCTIONAL REQUIREMENTS
   5.1 Performance Requirements
   5.2 Security Requirements
   5.3 Reliability Requirements
   5.4 Availability Requirements
   5.5 Maintainability Requirements
   5.6 Portability Requirements

6. DATABASE REQUIREMENTS
   6.1 Database Schema
   6.2 Data Dictionary

7. API SPECIFICATIONS
   7.1 Authentication APIs
   7.2 Question APIs
   7.3 Answer APIs
   7.4 Leaderboard APIs
   7.5 Profile APIs
   7.6 Chat APIs
   7.7 Notification APIs

8. DEVELOPMENT PLAN
   8.1 Development Phases
   8.2 Technology Stack
   8.3 Testing Strategy
   8.4 Deployment Plan

9. APPENDICES
   9.1 API Endpoint Reference
   9.2 Database Table Reference

========================================================================
1. INTRODUCTION
========================================================================

1.1 PURPOSE
-----------
This Software Requirements Specification (SRS) document provides a 
comprehensive description of the ASTU-Q mobile application, a peer-to-peer
doubt solver system designed for students. This document is intended for
developers, testers, project managers, and stakeholders involved in the
development and deployment of the ASTU-Q platform.

1.2 SCOPE
---------
The ASTU-Q application is a mobile platform that enables students to:
- Ask academic questions across various subjects
- Receive answers from peers and verified users
- Vote on answers and mark best answers
- Compete on leaderboards based on participation
- Chat with other users for real-time assistance
- Manage user profiles and track achievements

The system includes:
- Mobile application (Flutter)
- Backend API (PHP/MySQL)
- Admin dashboard for system management

1.3 DEFINITIONS, ACRONYMS, AND ABBREVIATIONS
------------------------------------------
- API: Application Programming Interface
- SRS: Software Requirements Specification
- UI: User Interface
- UX: User Experience
- JWT: JSON Web Token
- REST: Representational State Transfer
- CRUD: Create, Read, Update, Delete
- P2P: Peer-to-Peer
- ASTU: Adama Science and Technology University
- Dio: HTTP client for Dart
- GetIt: Dependency injection library

1.4 REFERENCES
--------------
- Flutter Framework Documentation
- Dart Language Specification
- PHP 8.x Documentation
- MySQL 8.0 Documentation
- REST API Best Practices
- OWASP Mobile Security Guidelines

1.5 OVERVIEW
------------
This SRS document is organized into the following sections:
- Section 2 describes the overall product functionality and environment
- Section 3 details specific system features and requirements
- Section 4 specifies external interface requirements
- Section 5 defines non-functional requirements
- Section 6 describes database requirements
- Section 7 provides detailed API specifications
- Section 8 outlines the development plan

========================================================================
2. OVERALL DESCRIPTION
========================================================================

2.1 PRODUCT PERSPECTIVE
-----------------------
ASTU-Q is a standalone mobile application that operates independently
but integrates with a backend server for data persistence and real-time
functionality. The system architecture consists of:

- CLIENT LAYER: Flutter mobile application (Android/iOS)
- PRESENTATION LAYER: UI components, providers, state management
- BUSINESS LOGIC LAYER: Use cases, repositories, domain entities
- DATA LAYER: Remote API calls, local storage, caching
- SERVER LAYER: PHP REST API
- DATABASE LAYER: MySQL relational database

2.2 PRODUCT FUNCTIONS
---------------------
The major functions of the ASTU-Q system include:

F-01: User Registration and Authentication
       - Email/password registration
       - Login with session management
       - Password recovery
       - Profile management

F-02: Question Management
       - Create questions with text and images
       - Categorize by subject
       - Edit and delete own questions
       - Search and filter questions

F-03: Answer Management
       - Post answers to questions
       - Vote answers (upvote/downvote)
       - Mark best answers
       - Edit and delete own answers

F-04: Leaderboard System
       - Rank users by points and activity
       - Filter by time period (today, week, month, year, all)
       - Filter by category (points, questions, answers, best answers)
       - Display badges and achievements

F-05: Real-time Chat
       - Direct messaging between users
       - Chat rooms for group discussions
       - Message status indicators

F-06: Notifications
       - Push notifications for answers
       - Achievement notifications
       - System announcements

F-07: Admin Dashboard
       - User management
       - Content moderation
       - Analytics and reporting
       - System configuration

2.3 USER CLASSES AND CHARACTERISTICS
------------------------------------

UC-01: Student (Regular User)
       - Primary user of the application
       - Can ask questions, answer questions, vote, chat
       - Views leaderboards and profiles
       - Receives notifications

UC-02: Verified User
       - Regular user with verified status
       - Higher credibility for answers
       - Special badge indicators

UC-03: Admin User
       - System administrators
       - Full access to admin dashboard
       - Can moderate content and manage users
       - Access to analytics and reports

2.4 OPERATING ENVIRONMENT
-------------------------

MOBILE CLIENT:
- Platform: Android 5.0+ (API 21+), iOS 12+
- Framework: Flutter 3.x
- Minimum RAM: 2GB
- Storage: 100MB minimum
- Network: Internet connection required

SERVER ENVIRONMENT:
- OS: Linux/Windows Server
- Web Server: Apache/Nginx
- PHP Version: 8.0+
- Database: MySQL 8.0+
- SSL Certificate: Required for HTTPS

2.5 DESIGN AND IMPLEMENTATION CONSTRAINTS
------------------------------------------
- Must comply with OWASP mobile security guidelines
- API responses must follow JSON format
- Must support offline mode for basic features
- Image uploads limited to 10MB per file
- Must implement proper error handling and logging
- Code must follow Clean Architecture principles
- UI must be responsive across all screen sizes

2.6 ASSUMPTIONS AND DEPENDENCIES
-------------------------------
- Users have smartphones with internet connectivity
- Backend server is properly configured and accessible
- Third-party services (push notifications) are available
- Database is maintained and backed up regularly
- PHP extensions (PDO, GD, cURL) are enabled

========================================================================
3. SYSTEM FEATURES
========================================================================

3.1 USER AUTHENTICATION MODULE
----------------------------

SF-1.1: User Registration
       Priority: High
       Description: Allow new users to create accounts
       Input: Name, email, password, confirm password, phone (optional)
       Processing: Validate input, check uniqueness, hash password,
                   create user record
       Output: Success message or validation errors
       API: POST /signup.php

SF-1.2: User Login
       Priority: High
       Description: Authenticate existing users
       Input: Email, password, remember me (optional)
       Processing: Validate credentials, generate token, create session
       Output: Auth token and user data
       API: POST /login.php

SF-1.3: Password Recovery
       Priority: Medium
       Description: Allow users to reset forgotten passwords
       Input: Registered email address
       Processing: Generate reset token, send email
       Output: Success/confirmation message
       API: POST /auth/forgot-password

SF-1.4: Logout
       Priority: High
       Description: Terminate user session
       Input: Current auth token
       Processing: Invalidate token, clear session
       Output: Success confirmation
       API: POST /auth/logout

3.2 QUESTION AND ANSWER MODULE
------------------------------

SF-2.1: Create Question
       Priority: High
       Description: Allow users to post new questions
       Input: Title, content, subject, images (optional), tags (optional)
       Processing: Validate content, upload images, save to database
       Output: Created question with ID
       API: POST /create_question.php

SF-2.2: Get Questions List
       Priority: High
       Description: Retrieve paginated list of questions
       Input: Page number, limit, subject filter, search query (optional)
       Processing: Query database with filters, pagination
       Output: List of questions with metadata
       API: GET /get_questions.php

SF-2.3: Get Question Detail
       Priority: High
       Description: Retrieve specific question with answers
       Input: Question ID, viewer ID (optional)
       Processing: Fetch question data, increment view count
       Output: Question details with answers list
       API: GET /get_question.php

SF-2.4: Update Question
       Priority: Medium
       Description: Allow authors to edit their questions
       Input: Question ID, updated fields
       Processing: Verify ownership, update records
       Output: Updated question data
       API: PUT /questions

SF-2.5: Delete Question
       Priority: Medium
       Description: Allow authors to delete their questions
       Input: Question ID
       Processing: Verify ownership, soft delete
       Output: Success confirmation
       API: DELETE /questions

SF-2.6: Create Answer
       Priority: High
       Description: Allow users to answer questions
       Input: Question ID, answer content, images (optional)
       Processing: Validate content, save to database
       Output: Created answer with ID
       API: POST /answers

SF-2.7: Vote on Answer
       Priority: High
       Description: Allow voting on answers
       Input: Answer ID, vote type (upvote/downvote)
       Processing: Update vote count, recalculate score
       Output: Updated vote count
       API: POST /answers/vote

SF-2.8: Mark Best Answer
       Priority: Medium
       Description: Allow question author to mark best answer
       Input: Answer ID
       Processing: Verify ownership, mark as best
       Output: Success confirmation
       API: POST /answers/best

3.3 LEADERBOARD MODULE
---------------------

SF-3.1: Get Leaderboard
       Priority: High
       Description: Retrieve ranked list of users
       Input: Page, limit, time filter, category
       Processing: Calculate rankings, apply filters
       Output: Paginated list of ranked users
       API: GET /leaderboard.php

SF-3.2: Get User Rank
       Priority: Medium
       Description: Get specific user's rank information
       Input: User ID, time filter, category
       Processing: Calculate user rank, get statistics
       Output: Rank data with user info
       API: GET /get_user_rank.php

SF-3.3: Get Leaderboard Statistics
       Priority: Medium
       Description: Retrieve overall leaderboard statistics
       Input: Time filter, category
       Processing: Aggregate statistics, calculate distributions
       Output: Statistics data with charts info
       API: GET /leaderboard_stats.php

3.4 CHAT MODULE
---------------

SF-4.1: Get Conversations
       Priority: Medium
       Description: Retrieve user's chat conversations
       Input: User ID
       Processing: Fetch conversation list
       Output: List of conversations
       API: GET /chat/conversations

SF-4.2: Get Messages
       Priority: Medium
       Description: Retrieve messages in a conversation
       Input: Conversation ID, page, limit
       Processing: Fetch messages with pagination
       Output: List of messages
       API: GET /chat/messages

SF-4.3: Send Message
       Priority: Medium
       Description: Send a new message
       Input: Conversation ID, message content
       Processing: Save message, update conversation
       Output: Created message
       API: POST /chat/send

3.5 PROFILE MANAGEMENT MODULE
-----------------------------

SF-5.1: Get User Profile
       Priority: High
       Description: Retrieve user profile information
       Input: User ID
       Processing: Fetch user data with statistics
       Output: User profile with activity data
       API: GET /users/profile

SF-5.2: Update Profile
       Priority: High
       Description: Allow users to update their profile
       Input: Name, email, phone, bio, avatar
       Processing: Validate input, update records
       Output: Updated profile data
       API: PUT /users/update

SF-5.3: Upload Avatar
       Priority: Medium
       Description: Allow users to upload profile picture
       Input: Image file
       Processing: Validate image, upload to server
       Output: Image URL
       API: POST /users/upload-avatar

SF-5.4: Change Password
       Priority: Medium
       Description: Allow users to change password
       Input: Current password, new password, confirm password
       Processing: Verify current password, update hash
       Output: Success confirmation
       API: POST /users/change-password

3.6 NOTIFICATION MODULE
-----------------------

SF-6.1: Get Notifications
       Priority: Medium
       Description: Retrieve user notifications
       Input: User ID, page, limit
       Processing: Fetch notifications with pagination
       Output: List of notifications
       API: GET /notifications/list

SF-6.2: Mark Notification Read
       Priority: Low
       Description: Mark specific notification as read
       Input: Notification ID
       Processing: Update read status
       Output: Success confirmation
       API: POST /notifications/read

3.7 ADMIN DASHBOARD MODULE
-------------------------

SF-7.1: User Management
       Priority: High
       Description: Manage system users
       Functions: View users, ban/unban, verify users
       API: Various admin endpoints

SF-7.2: Content Moderation
       Priority: High
       Description: Moderate questions and answers
       Functions: View reports, remove content, warn users

SF-7.3: Analytics Dashboard
       Priority: Medium
       Description: View system statistics
       Functions: User growth, activity metrics, popular content

========================================================================
4. EXTERNAL INTERFACE REQUIREMENTS
========================================================================

4.1 USER INTERFACES
-------------------

MOBILE APPLICATION:
- Splash Screen: App logo and loading indicator
- Onboarding: Feature introduction slides
- Login/Register: Authentication forms with validation
- Home: Question feed with search and filters
- Question Detail: Full question view with answers
- Ask Question: Form for creating new questions
- Leaderboard: Ranked user list with filters
- Chat: Conversation list and messaging interface
- Profile: User information and activity history
- Settings: App preferences and account settings
- Admin Dashboard: System management interface

DESIGN PRINCIPLES:
- Material Design 3 guidelines
- Responsive layout for all screen sizes
- Consistent color scheme and typography
- Accessibility support (screen readers, large text)
- Dark mode support (planned)

4.2 HARDWARE INTERFACES
-----------------------
- Camera: For capturing images to upload
- Gallery: For selecting images from device
- Storage: For caching data and images
- Network: Wi-Fi and mobile data connectivity

4.3 SOFTWARE INTERFACES
-----------------------
- Operating System: Android/iOS native APIs
- Flutter Framework: UI rendering and device interaction
- Image Processing: Image compression and format conversion
- Push Notifications: Firebase Cloud Messaging
- Analytics: Firebase Analytics (planned)

4.4 COMMUNICATIONS INTERFACES
-----------------------------
- Protocol: HTTPS for all API communications
- Data Format: JSON for request/response payloads
- Authentication: Bearer token in Authorization header
- File Upload: Multipart/form-data for images
- Real-time: WebSocket for chat (planned)

========================================================================
5. NON-FUNCTIONAL REQUIREMENTS
========================================================================

5.1 PERFORMANCE REQUIREMENTS
----------------------------
- App launch time: < 3 seconds
- API response time: < 2 seconds (95th percentile)
- Image upload time: < 10 seconds for 5MB
- List scroll performance: 60 FPS
- Database query time: < 500ms
- Concurrent users: Support 1000+ simultaneous users

5.2 SECURITY REQUIREMENTS
-------------------------
- Password hashing: bcrypt with salt
- API authentication: JWT tokens with expiration
- Data encryption: HTTPS for all transmissions
- Input validation: Server-side validation for all inputs
- SQL injection prevention: Parameterized queries
- XSS prevention: Output encoding for user content
- Rate limiting: 60 requests per minute per user
- File upload validation: Type and size checks

5.3 RELIABILITY REQUIREMENTS
----------------------------
- System uptime: 99.5% availability
- Data backup: Daily automated backups
- Error recovery: Graceful degradation for failures
- Data integrity: Transaction support for critical operations
- Session management: Secure token handling

5.4 AVAILABILITY REQUIREMENTS
-----------------------------
- Maintenance windows: Scheduled during low-traffic periods
- Zero-downtime deployments: Blue-green deployment strategy
- Monitoring: Real-time system health monitoring
- Alerts: Automated alerts for system failures

5.5 MAINTAINABILITY REQUIREMENTS
--------------------------------
- Code organization: Clean Architecture principles
- Documentation: Inline code documentation
- Testing: Unit tests, integration tests, UI tests
- Logging: Structured logging with severity levels
- Version control: Git with semantic versioning

5.6 PORTABILITY REQUIREMENTS
----------------------------
- Mobile platforms: Android and iOS
- Screen sizes: Phones and tablets
- OS versions: Android 5.0+, iOS 12+
- Localization: English (Amharic support planned)

========================================================================
6. DATABASE REQUIREMENTS
========================================================================

6.1 DATABASE SCHEMA OVERVIEW
----------------------------
Database Name: astuq_database
Character Set: utf8mb4
Collation: utf8mb4_unicode_ci

6.2 CORE TABLES
--------------

TABLE: users
- user_id (INT, PK, AUTO_INCREMENT)
- username (VARCHAR(50), UNIQUE, NOT NULL)
- email (VARCHAR(100), UNIQUE, NOT NULL)
- password_hash (VARCHAR(255), NOT NULL)
- first_name (VARCHAR(50), NOT NULL)
- last_name (VARCHAR(50), NOT NULL)
- profile_picture (VARCHAR(255), NULL)
- bio (TEXT, NULL)
- phone (VARCHAR(20), NULL)
- date_of_birth (DATE, NULL)
- status (ENUM: active, banned, suspended, pending, DEFAULT active)
- email_verified (BOOLEAN, DEFAULT FALSE)
- phone_verified (BOOLEAN, DEFAULT FALSE)
- points (INT, DEFAULT 0)
- level (INT, DEFAULT 1)
- badge_count (INT, DEFAULT 0)
- questions_asked (INT, DEFAULT 0)
- answers_given (INT, DEFAULT 0)
- best_answers (INT, DEFAULT 0)
- last_login (DATETIME, NULL)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- updated_at (TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP)

TABLE: questions
- question_id (INT, PK, AUTO_INCREMENT)
- user_id (INT, FK, NOT NULL)
- title (VARCHAR(255), NOT NULL)
- content (TEXT, NOT NULL)
- subject (VARCHAR(100), NOT NULL)
- status (ENUM: active, deleted, pending, DEFAULT active)
- views (INT, DEFAULT 0)
- upvotes (INT, DEFAULT 0)
- downvotes (INT, DEFAULT 0)
- accepted_answer_id (INT, NULL)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- updated_at (TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP)

TABLE: answers
- answer_id (INT, PK, AUTO_INCREMENT)
- question_id (INT, FK, NOT NULL)
- user_id (INT, FK, NOT NULL)
- content (TEXT, NOT NULL)
- status (ENUM: active, deleted, pending, DEFAULT active)
- upvotes (INT, DEFAULT 0)
- downvotes (INT, DEFAULT 0)
- is_best_answer (BOOLEAN, DEFAULT FALSE)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- updated_at (TIMESTAMP, ON UPDATE CURRENT_TIMESTAMP)

TABLE: roles
- role_id (INT, PK, AUTO_INCREMENT)
- role_name (VARCHAR(50), UNIQUE, NOT NULL)
- role_description (TEXT, NULL)
- permissions (JSON, NULL)
- is_system_role (BOOLEAN, DEFAULT FALSE)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

TABLE: user_roles
- user_role_id (INT, PK, AUTO_INCREMENT)
- user_id (INT, FK, NOT NULL)
- role_id (INT, FK, NOT NULL)
- assigned_by (INT, FK, NULL)
- assigned_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)
- expires_at (DATETIME, NULL)
- is_active (BOOLEAN, DEFAULT TRUE)

TABLE: notifications
- notification_id (INT, PK, AUTO_INCREMENT)
- user_id (INT, FK, NOT NULL)
- type (VARCHAR(50), NOT NULL)
- title (VARCHAR(255), NOT NULL)
- message (TEXT, NOT NULL)
- is_read (BOOLEAN, DEFAULT FALSE)
- created_at (TIMESTAMP, DEFAULT CURRENT_TIMESTAMP)

6.3 INDEXES
-----------
- users: idx_username, idx_email, idx_status, idx_points, idx_created_at
- questions: idx_user_id, idx_subject, idx_status, idx_created_at
- answers: idx_question_id, idx_user_id, idx_status
- notifications: idx_user_id, idx_is_read, idx_created_at

========================================================================
7. API SPECIFICATIONS
========================================================================

7.1 API BASE URL
----------------
Development: https://evadevstudio.com/sami
Production: [To be configured]

7.2 AUTHENTICATION
------------------
All API requests (except login/register) require Authorization header:
Authorization: Bearer <JWT_TOKEN>

7.3 STANDARD RESPONSE FORMAT
----------------------------
Success Response:
{
  "success": true,
  "data": { ... },
  "message": "Operation successful"
}

Error Response:
{
  "success": false,
  "message": "Error description",
  "error_code": "ERROR_CODE"
}

7.4 PAGINATION
--------------
Paginated endpoints accept:
- page: Page number (default: 1)
- limit: Items per page (default: 20, max: 100)

Paginated responses include:
{
  "success": true,
  "data": { ... },
  "pagination": {
    "currentPage": 1,
    "totalPages": 10,
    "totalItems": 200,
    "hasNextPage": true,
    "hasPreviousPage": false
  }
}

7.5 AUTHENTICATION APIs
-----------------------

POST /login.php
Request:
{
  "email": "user@example.com",
  "password": "password123",
  "remember_me": true
}

Response:
{
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "user@example.com",
      "avatar_url": "https://...",
      "points": 1500,
      "level": 15
    }
  }
}

POST /signup.php
Request:
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123",
  "confirm_password": "password123",
  "phone": "+1234567890"
}

Response:
{
  "success": true,
  "data": {
    "token": "jwt_token_here",
    "user": { ... }
  },
  "message": "Registration successful"
}

7.6 QUESTION APIs
-----------------

POST /create_question.php
Request:
{
  "title": "How to solve this equation?",
  "content": "Detailed question content...",
  "subject": "Mathematics",
  "images": ["base64_encoded_image"],
  "tags": ["algebra", "equations"]
}

GET /get_questions.php?page=1&limit=20&subject=Mathematics&search=algebra
Response:
{
  "success": true,
  "data": {
    "questions": [
      {
        "id": 1,
        "title": "Question title",
        "content": "Content preview...",
        "author": {
          "id": 1,
          "name": "John Doe",
          "avatar_url": "https://..."
        },
        "subject": "Mathematics",
        "status": "active",
        "views": 150,
        "answers_count": 5,
        "upvotes": 10,
        "created_at": "2026-05-01T10:00:00Z"
      }
    ]
  },
  "pagination": { ... }
}

GET /get_question.php?question_id=1&viewer_id=2
Response:
{
  "success": true,
  "data": {
    "question": { ... },
    "answers": [ ... ]
  }
}

7.7 ANSWER APIs
---------------

POST /answers
Request:
{
  "question_id": 1,
  "content": "Here's how to solve it...",
  "images": []
}

POST /answers/vote
Request:
{
  "answer_id": 1,
  "vote_type": "upvote"
}

POST /answers/best
Request:
{
  "answer_id": 1
}

7.8 LEADERBOARD APIs
--------------------

GET /leaderboard.php?page=1&limit=20&time_filter=all&category=points
Parameters:
- time_filter: today, week, month, year, all
- category: points, questions, answers, best_answers, upvotes

Response:
{
  "success": true,
  "data": {
    "users": [
      {
        "id": 1,
        "name": "John Doe",
        "avatarUrl": "https://...",
        "points": 1500,
        "level": 15,
        "badge": "Diamond",
        "questionsCount": 50,
        "answersCount": 200,
        "joinedAt": "2026-01-01T00:00:00Z"
      }
    ]
  },
  "pagination": { ... },
  "filters": {
    "timeFilter": "all",
    "category": "points"
  }
}

GET /get_user_rank.php?user_id=1&time_filter=all&category=points
Response:
{
  "success": true,
  "data": {
    "rank": 5,
    "userInfo": {
      "name": "John Doe",
      "points": 1500,
      "level": 15,
      "questionsCount": 50,
      "answersCount": 200,
      "bestAnswersCount": 30
    }
  }
}

GET /leaderboard_stats.php?time_filter=all&category=points
Response:
{
  "success": true,
  "data": {
    "stats": {
      "overview": {
        "totalUsers": 1000,
        "totalPoints": 500000,
        "avgPoints": 500,
        "maxPoints": 10000,
        "totalQuestions": 5000,
        "totalAnswers": 20000
      },
      "topPerformer": {
        "name": "John Doe",
        "points": 10000,
        "level": 50
      },
      "badgeDistribution": [
        {"badge": "Diamond", "count": 10},
        {"badge": "Platinum", "count": 50}
      ]
    }
  }
}

7.9 PROFILE APIs
----------------

GET /users/profile
Response:
{
  "success": true,
  "data": {
    "id": 1,
    "name": "John Doe",
    "email": "user@example.com",
    "avatar_url": "https://...",
    "bio": "Student at ASTU",
    "points": 1500,
    "level": 15,
    "questions_asked": 50,
    "answers_given": 200,
    "best_answers": 30,
    "created_at": "2026-01-01T00:00:00Z"
  }
}

PUT /users/update
Request:
{
  "name": "John Doe",
  "email": "newemail@example.com",
  "phone": "+1234567890",
  "bio": "Updated bio"
}

POST /users/upload-avatar
Content-Type: multipart/form-data
Request: file=image_file
Response:
{
  "success": true,
  "data": {
    "url": "https://evadevstudio.com/sami/uploads/avatars/1.jpg"
  }
}

POST /users/change-password
Request:
{
  "current_password": "oldpass123",
  "new_password": "newpass123",
  "confirm_password": "newpass123"
}

7.10 CHAT APIs
--------------

GET /chat/conversations
Response:
{
  "success": true,
  "data": {
    "conversations": [
      {
        "id": 1,
        "participant": {
          "id": 2,
          "name": "Jane Smith",
          "avatar_url": "https://..."
        },
        "last_message": "Thanks for the help!",
        "last_message_time": "2026-05-01T10:00:00Z",
        "unread_count": 2
      }
    ]
  }
}

GET /chat/messages?conversation_id=1&page=1&limit=20
Response:
{
  "success": true,
  "data": {
    "messages": [
      {
        "id": 1,
        "sender_id": 2,
        "content": "Hello!",
        "created_at": "2026-05-01T10:00:00Z",
        "is_read": true
      }
    ]
  }
}

POST /chat/send
Request:
{
  "conversation_id": 1,
  "content": "Thank you!"
}

7.11 NOTIFICATION APIs
----------------------

GET /notifications/list?page=1&limit=20
Response:
{
  "success": true,
  "data": {
    "notifications": [
      {
        "id": 1,
        "type": "answer",
        "title": "New Answer",
        "message": "Someone answered your question",
        "is_read": false,
        "created_at": "2026-05-01T10:00:00Z"
      }
    ]
  }
}

POST /notifications/read
Request:
{
  "notification_id": 1
}

========================================================================
8. DEVELOPMENT PLAN
========================================================================

8.1 TECHNOLOGY STACK
--------------------

FRONTEND:
- Framework: Flutter 3.x
- Language: Dart
- State Management: Provider + ChangeNotifier
- Dependency Injection: GetIt
- HTTP Client: Dio
- Local Storage: SharedPreferences, SecureStorage
- Image Handling: ImagePicker, CachedNetworkImage
- UI Components: Material Design 3

BACKEND:
- Language: PHP 8.x
- Web Server: Apache/Nginx
- Database: MySQL 8.0
- API Style: RESTful JSON
- Authentication: JWT Tokens
- File Storage: Local filesystem (production: S3)

DEVELOPMENT TOOLS:
- IDE: Android Studio / VS Code
- Version Control: Git
- API Testing: Postman / Insomnia
- Database Tool: phpMyAdmin / MySQL Workbench

8.2 DEVELOPMENT PHASES
----------------------

PHASE 1: PROJECT SETUP (Week 1)
- Environment setup
- Project scaffolding
- Architecture implementation
- Database design
- API endpoint planning

PHASE 2: CORE DEVELOPMENT (Weeks 2-4)
- Authentication module
- Question/Answer module
- Profile management
- Basic UI implementation
- API integration

PHASE 3: ADVANCED FEATURES (Weeks 5-6)
- Leaderboard system
- Chat functionality
- Image upload system
- Push notifications
- Search functionality

PHASE 4: ADMIN DASHBOARD (Week 7)
- Admin authentication
- User management
- Content moderation
- Analytics dashboard

PHASE 5: TESTING & QA (Week 8)
- Unit testing
- Integration testing
- UI testing
- Performance testing
- Security audit

PHASE 6: DEPLOYMENT (Week 9)
- Production server setup
- Database migration
- API deployment
- Mobile app build
- App store submission

PHASE 7: MAINTENANCE (Ongoing)
- Bug fixes
- Feature updates
- Performance optimization
- Security updates

8.3 TESTING STRATEGY
--------------------

UNIT TESTING:
- Test individual functions and methods
- Mock external dependencies
- Target: 80%+ code coverage

INTEGRATION TESTING:
- Test API endpoints
- Test database operations
- Test third-party integrations

UI TESTING:
- Test user flows
- Test responsive design
- Test on multiple devices

PERFORMANCE TESTING:
- Load testing for API
- Stress testing for database
- Memory leak detection

SECURITY TESTING:
- Penetration testing
- Vulnerability scanning
- Input validation testing

8.4 DEPLOYMENT PLAN
-------------------

DEVELOPMENT ENVIRONMENT:
- Local development machines
- Local PHP server
- Local MySQL database

STAGING ENVIRONMENT:
- Staging server
- Test database
- CI/CD pipeline

PRODUCTION ENVIRONMENT:
- Production server
- Production database
- Load balancer
- CDN for static assets
- Backup systems

========================================================================
9. APPENDICES
========================================================================

9.1 COMPLETE API ENDPOINT REFERENCE
-----------------------------------

AUTHENTICATION:
  POST /login.php                 - User login
  POST /signup.php                - User registration
  POST /auth/logout               - User logout
  POST /auth/refresh              - Refresh token
  POST /auth/forgot-password      - Password recovery
  POST /auth/reset-password       - Reset password
  POST /auth/verify-email         - Verify email

QUESTIONS:
  POST /create_question.php       - Create question
  GET  /get_questions.php         - List questions
  GET  /get_question.php          - Get question detail
  PUT  /questions                 - Update question
  DELETE /questions               - Delete question
  POST /questions/vote            - Vote on question

ANSWERS:
  POST /answers                   - Create answer
  PUT  /answers                   - Update answer
  DELETE /answers                 - Delete answer
  POST /answers/vote              - Vote on answer
  POST /answers/best              - Mark best answer

LEADERBOARD:
  GET  /leaderboard.php           - Get leaderboard
  GET  /get_user_rank.php         - Get user rank
  GET  /leaderboard_stats.php     - Get statistics

PROFILE:
  GET  /users/profile             - Get profile
  PUT  /users/update              - Update profile
  POST /users/upload-avatar       - Upload avatar
  POST /users/change-password     - Change password
  GET  /users/questions             - Get user questions
  GET  /users/answers               - Get user answers

CHAT:
  GET  /chat/conversations        - List conversations
  GET  /chat/messages             - Get messages
  POST /chat/send                 - Send message

NOTIFICATIONS:
  GET  /notifications/list        - List notifications
  POST /notifications/read        - Mark as read
  POST /notifications/read-all    - Mark all as read

UPLOAD:
  POST /upload/image              - Upload image
  POST /upload/document           - Upload document

ANALYTICS:
  GET  /analytics/user-stats        - User statistics
  GET  /analytics/question-stats   - Question statistics
  GET  /analytics/popular-subjects - Popular subjects

SUBJECTS:
  GET  /subjects/list             - List subjects
  GET  /subjects/categories       - Get categories

REPORTS:
  POST /reports/create            - Create report
  GET  /reports/list              - List reports
  PUT  /reports/update            - Update report

9.2 ERROR CODE REFERENCE
------------------------

NETWORK_ERROR          - Network connectivity issue
TIMEOUT_ERROR          - Request timeout
UNAUTHORIZED           - Authentication required
FORBIDDEN              - Permission denied
NOT_FOUND              - Resource not found
SERVER_ERROR           - Internal server error
VALIDATION_ERROR       - Input validation failed
FILE_TOO_LARGE         - Uploaded file exceeds limit
UNSUPPORTED_FILE_TYPE  - Invalid file type

========================================================================
DOCUMENT CONTROL
========================================================================

Version History:
  1.0 - Initial release - May 2026

Approval:
  Prepared by: Development Team
  Reviewed by: Project Manager
  Approved by: Stakeholders

========================================================================
END OF DOCUMENT
========================================================================
