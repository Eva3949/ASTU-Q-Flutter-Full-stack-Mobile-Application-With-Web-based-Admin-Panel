# Sample Test Data for ASTU-Q App

This document provides comprehensive sample data for testing various features of the ASTU-Q application.

## 1. User Sample Data

### Regular Users
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@astu.edu.et",
      "password": "password123",
      "phone": "+251911234567",
      "avatar_url": "https://example.com/avatars/john_doe.jpg",
      "bio": "Computer Science student interested in AI and Machine Learning",
      "email_verified_at": "2024-01-15T10:30:00Z",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T10:30:00Z",
      "roles": ["student"],
      "permissions": ["ask_questions", "answer_questions", "vote"],
      "is_active": true,
      "last_login_at": "2024-03-10T14:20:00Z",
      "questions_asked": 15,
      "answers_given": 23,
      "best_answers": 5,
      "reputation": 450
    },
    {
      "id": 2,
      "name": "Jane Smith",
      "email": "jane.smith@astu.edu.et",
      "password": "password123",
      "phone": "+251912345678",
      "avatar_url": "https://example.com/avatars/jane_smith.jpg",
      "bio": "Electrical Engineering student with passion for robotics",
      "email_verified_at": "2024-01-16T09:15:00Z",
      "created_at": "2024-01-02T00:00:00Z",
      "updated_at": "2024-01-16T09:15:00Z",
      "roles": ["student", "moderator"],
      "permissions": ["ask_questions", "answer_questions", "vote", "moderate"],
      "is_active": true,
      "last_login_at": "2024-03-11T16:45:00Z",
      "questions_asked": 8,
      "answers_given": 31,
      "best_answers": 12,
      "reputation": 780
    },
    {
      "id": 3,
      "name": "Dr. Michael Johnson",
      "email": "michael.johnson@astu.edu.et",
      "password": "password123",
      "phone": "+251913456789",
      "avatar_url": "https://example.com/avatars/michael_johnson.jpg",
      "bio": "Professor of Computer Science, specializing in algorithms and data structures",
      "email_verified_at": "2024-01-10T11:20:00Z",
      "created_at": "2023-12-15T00:00:00Z",
      "updated_at": "2024-02-20T14:30:00Z",
      "roles": ["professor", "admin"],
      "permissions": ["ask_questions", "answer_questions", "vote", "moderate", "admin"],
      "is_active": true,
      "last_login_at": "2024-03-11T09:00:00Z",
      "questions_asked": 5,
      "answers_given": 67,
      "best_answers": 28,
      "reputation": 2100
    }
  ]
}
```

### User Profile Data
```json
{
  "user_profile": {
    "id": 1,
    "name": "John Doe",
    "email": "john.doe@astu.edu.et",
    "phone": "+251911234567",
    "avatar_url": "https://example.com/avatars/john_doe.jpg",
    "bio": "Computer Science student interested in AI and Machine Learning",
    "department": "Computer Science",
    "year_of_study": "3rd Year",
    "interests": ["AI", "Machine Learning", "Web Development", "Mobile Apps"],
    "social_links": {
      "github": "https://github.com/johndoe",
      "linkedin": "https://linkedin.com/in/johndoe",
      "twitter": "https://twitter.com/johndoe"
    },
    "stats": {
      "questions_asked": 15,
      "answers_given": 23,
      "best_answers": 5,
      "reputation": 450,
      "followers": 23,
      "following": 45
    },
    "achievements": [
      {
        "id": 1,
        "name": "Question Master",
        "description": "Asked 10+ questions",
        "icon": "question_answer",
        "earned_at": "2024-02-15T10:00:00Z"
      },
      {
        "id": 2,
        "name": "Helpful Answerer",
        "description": "Provided 20+ answers",
        "icon": "thumb_up",
        "earned_at": "2024-02-28T15:30:00Z"
      }
    ]
  }
}
```

## 2. Questions Sample Data

### Question Categories
```json
{
  "categories": [
    {
      "id": 1,
      "name": "Computer Science",
      "description": "Questions related to programming, algorithms, software development",
      "icon": "computer",
      "color": "#2196F3",
      "question_count": 234
    },
    {
      "id": 2,
      "name": "Mathematics",
      "description": "Mathematics questions and problem solving",
      "icon": "calculate",
      "color": "#4CAF50",
      "question_count": 189
    },
    {
      "id": 3,
      "name": "Physics",
      "description": "Physics concepts and problem solving",
      "icon": "science",
      "color": "#FF9800",
      "question_count": 156
    },
    {
      "id": 4,
      "name": "Chemistry",
      "description": "Chemistry questions and chemical reactions",
      "icon": "biotech",
      "color": "#9C27B0",
      "question_count": 98
    },
    {
      "id": 5,
      "name": "Engineering",
      "description": "Various engineering disciplines",
      "icon": "engineering",
      "color": "#F44336",
      "question_count": 312
    }
  ]
}
```

### Sample Questions
```json
{
  "questions": [
    {
      "id": 1,
      "title": "How does the QuickSort algorithm work?",
      "content": "I'm studying sorting algorithms and I'm having trouble understanding how QuickSort works. Can someone explain the concept with a simple example? I understand that it uses divide and conquer, but I'm confused about the partitioning step.",
      "author_id": 1,
      "author_name": "John Doe",
      "author_avatar_url": "https://example.com/avatars/john_doe.jpg",
      "author_is_verified": false,
      "category_id": 1,
      "category_name": "Computer Science",
      "tags": ["algorithms", "sorting", "quicksort", "divide-and-conquer"],
      "upvotes": 12,
      "downvotes": 2,
      "view_count": 156,
      "answer_count": 3,
      "has_accepted_answer": true,
      "is_bookmarked": false,
      "is_upvoted": false,
      "is_downvoted": false,
      "created_at": "2024-03-10T14:30:00Z",
      "updated_at": "2024-03-10T14:30:00Z"
    },
    {
      "id": 2,
      "title": "Best resources for learning Flutter development?",
      "content": "I'm a beginner in mobile app development and I want to learn Flutter. What are the best resources (books, courses, tutorials) you would recommend? I have some experience with basic programming concepts.",
      "author_id": 2,
      "author_name": "Jane Smith",
      "author_avatar_url": "https://example.com/avatars/jane_smith.jpg",
      "author_is_verified": true,
      "category_id": 1,
      "category_name": "Computer Science",
      "tags": ["flutter", "mobile-development", "learning-resources", "beginner"],
      "upvotes": 25,
      "downvotes": 1,
      "view_count": 289,
      "answer_count": 7,
      "has_accepted_answer": false,
      "is_bookmarked": true,
      "is_upvoted": true,
      "is_downvoted": false,
      "created_at": "2024-03-09T10:15:00Z",
      "updated_at": "2024-03-09T10:15:00Z"
    },
    {
      "id": 3,
      "title": "Understanding Newton's Third Law",
      "content": "I'm confused about Newton's Third Law of Motion. If every action has an equal and opposite reaction, how does anything move? For example, when I push a wall, the wall pushes back with equal force, so why doesn't the wall move? Can someone explain this concept clearly?",
      "author_id": 1,
      "author_name": "John Doe",
      "author_avatar_url": "https://example.com/avatars/john_doe.jpg",
      "author_is_verified": false,
      "category_id": 3,
      "category_name": "Physics",
      "tags": ["physics", "newton-laws", "mechanics", "forces"],
      "upvotes": 18,
      "downvotes": 0,
      "view_count": 124,
      "answer_count": 4,
      "has_accepted_answer": true,
      "is_bookmarked": false,
      "is_upvoted": false,
      "is_downvoted": false,
      "created_at": "2024-03-08T16:45:00Z",
      "updated_at": "2024-03-08T16:45:00Z"
    }
  ]
}
```

### Question Detail Example
```json
{
  "question_detail": {
    "id": 1,
    "title": "How does the QuickSort algorithm work?",
    "content": "I'm studying sorting algorithms and I'm having trouble understanding how QuickSort works. Can someone explain the concept with a simple example? I understand that it uses divide and conquer, but I'm confused about the partitioning step.",
    "author": {
      "id": 1,
      "name": "John Doe",
      "avatar_url": "https://example.com/avatars/john_doe.jpg",
      "is_verified": false,
      "reputation": 450
    },
    "category": {
      "id": 1,
      "name": "Computer Science",
      "icon": "computer",
      "color": "#2196F3"
    },
    "tags": ["algorithms", "sorting", "quicksort", "divide-and-conquer"],
    "stats": {
      "upvotes": 12,
      "downvotes": 2,
      "view_count": 156,
      "answer_count": 3,
      "bookmark_count": 8
    },
    "user_interaction": {
      "is_upvoted": false,
      "is_downvoted": false,
      "is_bookmarked": false,
      "is_following": false
    },
    "created_at": "2024-03-10T14:30:00Z",
    "updated_at": "2024-03-10T14:30:00Z",
    "has_accepted_answer": true,
    "answers": [
      {
        "id": 1,
        "content": "QuickSort is a divide-and-conquer algorithm that works by selecting a 'pivot' element from the array and partitioning the other elements into two sub-arrays, according to whether they are less than or greater than the pivot. Here's how it works:\n\n1. **Choose a pivot**: Select an element from the array (commonly the first, last, middle, or random element).\n2. **Partition**: Rearrange the array so that all elements less than the pivot come before it, while all elements greater than the pivot come after it.\n3. **Recursively sort**: Apply the same algorithm to the sub-arrays of elements less than and greater than the pivot.\n\nFor example, with array [3, 6, 8, 10, 1, 2, 1]:\n- Choose pivot = 6\n- Partition: [3, 1, 2, 1, 6, 8, 10]\n- Recursively sort left part [3, 1, 2, 1] and right part [8, 10]\n\nThe time complexity is O(n log n) on average and O(n²) in worst case.",
        "author": {
          "id": 3,
          "name": "Dr. Michael Johnson",
          "avatar_url": "https://example.com/avatars/michael_johnson.jpg",
          "is_verified": true,
          "reputation": 2100
        },
        "stats": {
          "upvotes": 15,
          "downvotes": 0,
          "is_accepted": true
        },
        "user_interaction": {
          "is_upvoted": true,
          "is_downvoted": false
        },
        "created_at": "2024-03-10T15:00:00Z",
        "updated_at": "2024-03-10T15:00:00Z"
      },
      {
        "id": 2,
        "content": "To add to the excellent explanation above, here's a simple implementation in Python:\n\n```python\ndef quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n    \n    pivot = arr[len(arr) // 2]\n    left = [x for x in arr if x < pivot]\n    middle = [x for x in arr if x == pivot]\n    right = [x for x in arr if x > pivot]\n    \n    return quicksort(left) + middle + quicksort(right)\n\n# Example usage\narr = [3, 6, 8, 10, 1, 2, 1]\nprint(quicksort(arr))  # Output: [1, 1, 2, 3, 6, 8, 10]\n```\n\nThe key insight is that the partition step ensures that every element in the left sub-array is less than the pivot, and every element in the right sub-array is greater than the pivot.",
        "author": {
          "id": 2,
          "name": "Jane Smith",
          "avatar_url": "https://example.com/avatars/jane_smith.jpg",
          "is_verified": true,
          "reputation": 780
        },
        "stats": {
          "upvotes": 8,
          "downvotes": 0,
          "is_accepted": false
        },
        "user_interaction": {
          "is_upvoted": false,
          "is_downvoted": false
        },
        "created_at": "2024-03-10T15:30:00Z",
        "updated_at": "2024-03-10T15:30:00Z"
      }
    ]
  }
}
```

## 3. Answers Sample Data

### Sample Answers
```json
{
  "answers": [
    {
      "id": 1,
      "question_id": 1,
      "content": "QuickSort is a divide-and-conquer algorithm that works by selecting a 'pivot' element from the array and partitioning the other elements into two sub-arrays, according to whether they are less than or greater than the pivot. Here's how it works:\n\n1. **Choose a pivot**: Select an element from the array (commonly the first, last, middle, or random element).\n2. **Partition**: Rearrange the array so that all elements less than the pivot come before it, while all elements greater than the pivot come after it.\n3. **Recursively sort**: Apply the same algorithm to the sub-arrays of elements less than and greater than the pivot.\n\nFor example, with array [3, 6, 8, 10, 1, 2, 1]:\n- Choose pivot = 6\n- Partition: [3, 1, 2, 1, 6, 8, 10]\n- Recursively sort left part [3, 1, 2, 1] and right part [8, 10]\n\nThe time complexity is O(n log n) on average and O(n²) in worst case.",
      "author_id": 3,
      "author_name": "Dr. Michael Johnson",
      "author_avatar_url": "https://example.com/avatars/michael_johnson.jpg",
      "author_is_verified": true,
      "upvotes": 15,
      "downvotes": 0,
      "is_accepted": true,
      "is_upvoted": true,
      "is_downvoted": false,
      "created_at": "2024-03-10T15:00:00Z",
      "updated_at": "2024-03-10T15:00:00Z"
    },
    {
      "id": 2,
      "question_id": 1,
      "content": "To add to the excellent explanation above, here's a simple implementation in Python:\n\n```python\ndef quicksort(arr):\n    if len(arr) <= 1:\n        return arr\n    \n    pivot = arr[len(arr) // 2]\n    left = [x for x in arr if x < pivot]\n    middle = [x for x in arr if x == pivot]\n    right = [x for x in arr if x > pivot]\n    \n    return quicksort(left) + middle + quicksort(right)\n\n# Example usage\narr = [3, 6, 8, 10, 1, 2, 1]\nprint(quicksort(arr))  # Output: [1, 1, 2, 3, 6, 8, 10]\n```\n\nThe key insight is that the partition step ensures that every element in the left sub-array is less than the pivot, and every element in the right sub-array is greater than the pivot.",
      "author_id": 2,
      "author_name": "Jane Smith",
      "author_avatar_url": "https://example.com/avatars/jane_smith.jpg",
      "author_is_verified": true,
      "upvotes": 8,
      "downvotes": 0,
      "is_accepted": false,
      "is_upvoted": false,
      "is_downvoted": false,
      "created_at": "2024-03-10T15:30:00Z",
      "updated_at": "2024-03-10T15:30:00Z"
    }
  ]
}
```

## 4. Chat Sample Data

### Chat Rooms
```json
{
  "chat_rooms": [
    {
      "id": 1,
      "name": "Computer Science Study Group",
      "description": "A group for CS students to discuss assignments and concepts",
      "type": "group",
      "avatar_url": "https://example.com/chat_rooms/cs_group.jpg",
      "created_by": 3,
      "created_by_name": "Dr. Michael Johnson",
      "participant_count": 25,
      "message_count": 156,
      "last_message": {
        "id": 156,
        "content": "Anyone working on the algorithms assignment?",
        "author_name": "Jane Smith",
        "timestamp": "2024-03-11T16:30:00Z"
      },
      "is_joined": true,
      "is_muted": false,
      "has_unread_messages": true,
      "unread_count": 3,
      "created_at": "2024-02-15T10:00:00Z",
      "updated_at": "2024-03-11T16:30:00Z"
    },
    {
      "id": 2,
      "name": "Flutter Development",
      "description": "Discuss Flutter development and share resources",
      "type": "public",
      "avatar_url": "https://example.com/chat_rooms/flutter.jpg",
      "created_by": 2,
      "created_by_name": "Jane Smith",
      "participant_count": 48,
      "message_count": 289,
      "last_message": {
        "id": 289,
        "content": "Check out this new Flutter tutorial!",
        "author_name": "John Doe",
        "timestamp": "2024-03-11T15:45:00Z"
      },
      "is_joined": true,
      "is_muted": false,
      "has_unread_messages": false,
      "unread_count": 0,
      "created_at": "2024-01-20T14:30:00Z",
      "updated_at": "2024-03-11T15:45:00Z"
    }
  ]
}
```

### Chat Messages
```json
{
  "chat_messages": [
    {
      "id": 1,
      "room_id": 1,
      "content": "Hey everyone! Anyone working on the algorithms assignment?",
      "author_id": 2,
      "author_name": "Jane Smith",
      "author_avatar_url": "https://example.com/avatars/jane_smith.jpg",
      "type": "text",
      "reply_to": null,
      "attachments": [],
      "reactions": [
        {
          "emoji": "thumbs_up",
          "count": 3,
          "users": [1, 3, 4]
        }
      ],
      "is_edited": false,
      "is_deleted": false,
      "created_at": "2024-03-11T16:30:00Z",
      "updated_at": "2024-03-11T16:30:00Z"
    },
    {
      "id": 2,
      "room_id": 1,
      "content": "Yes! I'm stuck on problem 3. The QuickSort implementation is confusing me.",
      "author_id": 1,
      "author_name": "John Doe",
      "author_avatar_url": "https://example.com/avatars/john_doe.jpg",
      "type": "text",
      "reply_to": 1,
      "attachments": [],
      "reactions": [
        {
          "emoji": "thinking_face",
          "count": 2,
          "users": [2, 3]
        }
      ],
      "is_edited": false,
      "is_deleted": false,
      "created_at": "2024-03-11T16:32:00Z",
      "updated_at": "2024-03-11T16:32:00Z"
    },
    {
      "id": 3,
      "room_id": 1,
      "content": "I can help! Let me share my implementation.",
      "author_id": 3,
      "author_name": "Dr. Michael Johnson",
      "author_avatar_url": "https://example.com/avatars/michael_johnson.jpg",
      "type": "file",
      "reply_to": 2,
      "attachments": [
        {
          "id": 1,
          "name": "quicksort_implementation.py",
          "url": "https://example.com/files/quicksort_implementation.py",
          "size": 2048,
          "type": "code"
        }
      ],
      "reactions": [
        {
          "emoji": "heart",
          "count": 5,
          "users": [1, 2, 4, 5, 6]
        }
      ],
      "is_edited": false,
      "is_deleted": false,
      "created_at": "2024-03-11T16:35:00Z",
      "updated_at": "2024-03-11T16:35:00Z"
    }
  ]
}
```

## 5. Notifications Sample Data

### Notification Types
```json
{
  "notifications": [
    {
      "id": 1,
      "type": "answer",
      "title": "New Answer to Your Question",
      "message": "Dr. Michael Johnson answered your question about QuickSort",
      "data": {
        "question_id": 1,
        "question_title": "How does the QuickSort algorithm work?",
        "answer_id": 1,
        "answerer_name": "Dr. Michael Johnson"
      },
      "is_read": false,
      "created_at": "2024-03-10T15:00:00Z"
    },
    {
      "id": 2,
      "type": "vote",
      "title": "Your Answer Received Upvotes",
      "message": "Your answer about QuickSort received 5 upvotes",
      "data": {
        "answer_id": 2,
        "question_id": 1,
        "question_title": "How does the QuickSort algorithm work?",
        "vote_count": 5
      },
      "is_read": false,
      "created_at": "2024-03-10T16:00:00Z"
    },
    {
      "id": 3,
      "type": "mention",
      "title": "You Were Mentioned",
      "message": "Jane Smith mentioned you in a chat message",
      "data": {
        "chat_room_id": 1,
        "chat_room_name": "Computer Science Study Group",
        "message_id": 2,
        "mentioner_name": "Jane Smith"
      },
      "is_read": true,
      "created_at": "2024-03-11T16:32:00Z"
    },
    {
      "id": 4,
      "type": "follow",
      "title": "New Follower",
      "message": "Jane Smith started following you",
      "data": {
        "follower_id": 2,
        "follower_name": "Jane Smith",
        "follower_avatar": "https://example.com/avatars/jane_smith.jpg"
      },
      "is_read": false,
      "created_at": "2024-03-11T14:20:00Z"
    }
  ]
}
```

## 6. Analytics Sample Data

### Analytics Overview
```json
{
  "analytics_overview": {
    "total_users": 1234,
    "active_users_today": 89,
    "total_questions": 5678,
    "total_answers": 12345,
    "questions_today": 23,
    "answers_today": 45,
    "engagement_rate": 0.67,
    "avg_response_time_minutes": 45,
    "top_categories": [
      {
        "name": "Computer Science",
        "question_count": 234,
        "percentage": 41.2
      },
      {
        "name": "Engineering",
        "question_count": 156,
        "percentage": 27.5
      },
      {
        "name": "Mathematics",
        "question_count": 98,
        "percentage": 17.3
      }
    ],
    "user_growth": {
      "this_month": 45,
      "last_month": 38,
      "growth_rate": 0.184
    },
    "question_trend": {
      "daily": [
        {"date": "2024-03-01", "count": 12},
        {"date": "2024-03-02", "count": 15},
        {"date": "2024-03-03", "count": 18},
        {"date": "2024-03-04", "count": 14},
        {"date": "2024-03-05", "count": 22},
        {"date": "2024-03-06", "count": 19},
        {"date": "2024-03-07", "count": 25}
      ]
    }
  }
}
```

## 7. API Response Examples

### Login Response
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": 1,
      "name": "John Doe",
      "email": "john.doe@astu.edu.et",
      "avatar_url": "https://example.com/avatars/john_doe.jpg",
      "roles": ["student"],
      "permissions": ["ask_questions", "answer_questions", "vote"]
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expires_in": 3600,
    "remember_me": false
  }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Validation failed",
  "errors": {
    "email": ["The email field is required."],
    "password": ["The password must be at least 8 characters."]
  },
  "code": 422
}
```

### Paginated Response
```json
{
  "success": true,
  "data": {
    "items": [...],
    "pagination": {
      "current_page": 1,
      "per_page": 20,
      "total": 156,
      "total_pages": 8,
      "has_more": true,
      "has_prev": false
    }
  }
}
```

## 8. Test Scenarios

### Authentication Test Cases
```json
{
  "auth_test_cases": [
    {
      "scenario": "Successful Login",
      "input": {
        "email": "john.doe@astu.edu.et",
        "password": "password123"
      },
      "expected": {
        "success": true,
        "user_id": 1,
        "has_token": true
      }
    },
    {
      "scenario": "Invalid Email",
      "input": {
        "email": "invalid@email",
        "password": "password123"
      },
      "expected": {
        "success": false,
        "error": "Invalid email format"
      }
    },
    {
      "scenario": "Wrong Password",
      "input": {
        "email": "john.doe@astu.edu.et",
        "password": "wrongpassword"
      },
      "expected": {
        "success": false,
        "error": "Invalid credentials"
      }
    }
  ]
}
```

### Question Test Cases
```json
{
  "question_test_cases": [
    {
      "scenario": "Create Valid Question",
      "input": {
        "title": "How does recursion work?",
        "content": "I need help understanding recursion in programming.",
        "category_id": 1,
        "tags": ["recursion", "programming"]
      },
      "expected": {
        "success": true,
        "question_id": 1
      }
    },
    {
      "scenario": "Empty Title",
      "input": {
        "title": "",
        "content": "Some content",
        "category_id": 1,
        "tags": []
      },
      "expected": {
        "success": false,
        "error": "Title is required"
      }
    }
  ]
}
```

## 9. Performance Test Data

### Large Dataset
```json
{
  "large_dataset": {
    "users": 1000,
    "questions": 5000,
    "answers": 15000,
    "chat_messages": 50000,
    "notifications": 10000
  }
}
```

### Stress Test Data
```json
{
  "stress_test": {
    "concurrent_users": 100,
    "requests_per_second": 50,
    "test_duration_minutes": 10,
    "expected_response_time_ms": 200,
    "expected_success_rate": 0.99
  }
}
```

## 10. Edge Cases

### Edge Case Data
```json
{
  "edge_cases": {
    "empty_database": {
      "users": 0,
      "questions": 0,
      "answers": 0
    },
    "single_user": {
      "users": 1,
      "questions": 0,
      "answers": 0
    },
    "max_content": {
      "title": "A".repeat(255),
      "content": "B".repeat(10000),
      "tags": ["tag".repeat(50)]
    },
    "special_characters": {
      "title": "How to handle @#$%^&*() in code?",
      "content": "Special chars: àáâãäåæçèéêë ìíîïñòóôõö ùúûüýÿ",
      "tags": ["unicode", "special-chars", "émojis: test"]
    }
  }
}
```

This sample data covers all major features of the ASTU-Q application and can be used for testing, development, and demonstration purposes.
