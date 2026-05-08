-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Apr 17, 2026 at 12:39 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `astu_q`
--

-- --------------------------------------------------------

--
-- Table structure for table `admin_logs`
--

CREATE TABLE `admin_logs` (
  `log_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `action` enum('create','update','delete','moderate','login') NOT NULL,
  `entity_type` enum('question','answer','user','report','notification') NOT NULL,
  `entity_id` int(11) DEFAULT NULL,
  `old_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`old_data`)),
  `new_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`new_data`)),
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `answers`
--

CREATE TABLE `answers` (
  `answer_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `content` text NOT NULL,
  `status` enum('pending','approved','rejected','deleted') DEFAULT 'pending',
  `is_best` tinyint(1) DEFAULT 0,
  `upvotes` int(11) DEFAULT 0,
  `downvotes` int(11) DEFAULT 0,
  `moderated_by` int(11) DEFAULT NULL,
  `moderated_at` timestamp NULL DEFAULT NULL,
  `moderation_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `answers`
--

INSERT INTO `answers` (`answer_id`, `question_id`, `user_id`, `content`, `status`, `is_best`, `upvotes`, `downvotes`, `moderated_by`, `moderated_at`, `moderation_reason`, `created_at`, `updated_at`) VALUES
(1, 1, 2, 'For quadratic equations, I recommend using the quadratic formula: x = [-b ± sqrt(b²-4ac)]/2a. First identify a, b, and c from your equation ax² + bx + c = 0. Then plug them into the formula. Practice with different examples to get comfortable with the process!', 'approved', 1, 2, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(2, 2, 1, 'HTML5 introduces semantic elements like <header>, <nav>, <article>, etc., and removes presentational elements. It also adds new form input types, multimedia support, and better APIs. The main difference is that HTML5 focuses on meaning and structure rather than just presentation.', 'approved', 0, 1, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(3, 3, 2, 'Key best practices: 1) Use Third Normal Form (3NF) for most cases, 2) Create proper indexes on frequently queried columns, 3) Use appropriate data types, 4) Plan relationships carefully, 5) Avoid data redundancy, and 6) Document your schema.', 'approved', 1, 1, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(4, 4, 3, 'Flutter is great for cross-platform development with a single codebase. React has a larger ecosystem but requires platform-specific code. Choose Flutter if you want native performance with less code, React if you need web support or prefer JavaScript.', 'approved', 0, 1, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(5, 5, 1, 'Machine learning is about teaching computers to learn patterns from data. Start with basic concepts like supervised vs unsupervised learning, then try simple projects like classification or regression. Online courses from Coursera or edX are great starting points!', 'approved', 1, 1, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(6, 6, 2, 'Practice regularly, start with small audiences, join Toastmasters, use breathing techniques, and remember that nervousness is normal. Focus on your message rather than how you\'re perceived. Preparation builds confidence!', 'approved', 0, 1, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11');

-- --------------------------------------------------------

--
-- Table structure for table `answer_votes`
--

CREATE TABLE `answer_votes` (
  `vote_id` int(11) NOT NULL,
  `answer_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `vote_type` enum('up','down') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `answer_votes`
--

INSERT INTO `answer_votes` (`vote_id`, `answer_id`, `user_id`, `vote_type`, `created_at`) VALUES
(1, 1, 1, 'up', '2026-04-16 06:54:11'),
(2, 1, 3, 'up', '2026-04-16 06:54:11'),
(3, 2, 2, 'up', '2026-04-16 06:54:11'),
(4, 3, 2, 'up', '2026-04-16 06:54:11'),
(5, 4, 1, 'up', '2026-04-16 06:54:11'),
(6, 5, 3, 'up', '2026-04-16 06:54:11'),
(7, 6, 2, 'up', '2026-04-16 06:54:11');

--
-- Triggers `answer_votes`
--
DELIMITER $$
CREATE TRIGGER `remove_answer_vote` AFTER DELETE ON `answer_votes` FOR EACH ROW BEGIN
    UPDATE answers SET 
        upvotes = (SELECT COUNT(*) FROM answer_votes WHERE answer_id = OLD.answer_id AND vote_type = 'up'),
        downvotes = (SELECT COUNT(*) FROM answer_votes WHERE answer_id = OLD.answer_id AND vote_type = 'down')
    WHERE answer_id = OLD.answer_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_answer_downvotes` AFTER INSERT ON `answer_votes` FOR EACH ROW BEGIN
    UPDATE answers SET 
        downvotes = (SELECT COUNT(*) FROM answer_votes WHERE answer_id = NEW.answer_id AND vote_type = 'down')
    WHERE answer_id = NEW.answer_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_answer_upvotes` AFTER INSERT ON `answer_votes` FOR EACH ROW BEGIN
    UPDATE answers SET 
        upvotes = (SELECT COUNT(*) FROM answer_votes WHERE answer_id = NEW.answer_id AND vote_type = 'up')
    WHERE answer_id = NEW.answer_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `auth_tokens`
--

CREATE TABLE `auth_tokens` (
  `token_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `device_info` text DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `bookmarks`
--

CREATE TABLE `bookmarks` (
  `bookmark_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `type` enum('welcome','question_approved','question_rejected','answer_approved','answer_rejected','best_answer','vote','comment','system','warning') NOT NULL,
  `title` varchar(255) NOT NULL,
  `message` text NOT NULL,
  `priority` enum('low','medium','high') DEFAULT 'medium',
  `is_read` tinyint(1) DEFAULT 0,
  `read_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `notifications`
--

INSERT INTO `notifications` (`notification_id`, `user_id`, `type`, `title`, `message`, `priority`, `is_read`, `read_at`, `created_at`) VALUES
(1, 1, 'welcome', 'Welcome to ASTU-Q!', 'Thank you for joining our community. Feel free to ask questions and help others.', 'low', 0, NULL, '2026-04-16 06:54:11'),
(2, 2, 'answer_approved', 'Your answer was approved!', 'Your answer to \"How to solve quadratic equations?\" has been approved and is now visible to other users.', 'medium', 0, NULL, '2026-04-16 06:54:11'),
(3, 3, 'best_answer', 'Your answer was marked as best!', 'Congratulations! Your answer to \"What is the difference between HTML and HTML5?\" was marked as the best answer by the question author.', 'high', 0, NULL, '2026-04-16 06:54:11');

-- --------------------------------------------------------

--
-- Table structure for table `password_resets`
--

CREATE TABLE `password_resets` (
  `reset_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `token` varchar(255) NOT NULL,
  `expires_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `used` tinyint(1) DEFAULT 0,
  `used_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `questions`
--

CREATE TABLE `questions` (
  `question_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` text NOT NULL,
  `subject` varchar(100) NOT NULL,
  `category` varchar(100) DEFAULT NULL,
  `tags` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`tags`)),
  `images` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`images`)),
  `status` enum('pending','approved','rejected','deleted') DEFAULT 'pending',
  `featured` tinyint(1) DEFAULT 0,
  `view_count` int(11) DEFAULT 0,
  `upvotes` int(11) DEFAULT 0,
  `downvotes` int(11) DEFAULT 0,
  `answer_count` int(11) DEFAULT 0,
  `moderated_by` int(11) DEFAULT NULL,
  `moderated_at` timestamp NULL DEFAULT NULL,
  `moderation_reason` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `questions`
--

INSERT INTO `questions` (`question_id`, `user_id`, `title`, `content`, `subject`, `category`, `tags`, `images`, `status`, `featured`, `view_count`, `upvotes`, `downvotes`, `answer_count`, `moderated_by`, `moderated_at`, `moderation_reason`, `created_at`, `updated_at`) VALUES
(1, 1, 'How to solve quadratic equations?', 'I need help solving quadratic equations for my math class. I understand the basic formula but get confused with the steps.', 'Mathematics', NULL, '[\"algebra\", \"equations\", \"homework\"]', NULL, 'approved', 0, 0, 1, 0, 1, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(2, 2, 'What is the difference between HTML and HTML5?', 'I keep hearing about HTML5 but I\'m not sure what makes it different from regular HTML. Can someone explain the main differences?', 'Web Development', NULL, '[\"html\", \"html5\", \"web\"]', NULL, 'approved', 0, 0, 1, 0, 1, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(3, 3, 'Best practices for database design?', 'I\'m designing a database for my project and want to know what are the best practices for normalization and indexing.', 'Computer Science', NULL, '[\"database\", \"design\", \"normalization\"]', NULL, 'approved', 0, 0, 1, 0, 1, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(4, 1, 'How to study effectively for exams?', 'I have exams coming up and I want to improve my study habits. What techniques work best for you?', 'Study Tips', NULL, '[\"study\", \"exams\", \"education\"]', NULL, 'approved', 0, 0, 1, 0, 1, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(5, 3, 'Flutter vs React for mobile apps?', 'I\'m trying to decide between Flutter and React for my next mobile app project. What are the pros and cons of each?', 'Programming', NULL, '[\"flutter\", \"react\", \"mobile\"]', NULL, 'approved', 0, 0, 1, 0, 1, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(6, 2, 'What is machine learning?', 'I keep hearing about machine learning but don\'t really understand what it is or how it works. Can someone explain in simple terms?', 'Computer Science', NULL, '[\"machine-learning\", \"ai\", \"concepts\"]', NULL, 'approved', 0, 0, 1, 0, 1, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(7, 1, 'How to improve public speaking skills?', 'I get nervous when speaking in public and want to improve my presentation skills. Any tips?', 'Personal Development', NULL, '[\"public-speaking\", \"communication\", \"skills\"]', NULL, 'approved', 0, 0, 0, 0, 0, NULL, NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11');

-- --------------------------------------------------------

--
-- Table structure for table `question_votes`
--

CREATE TABLE `question_votes` (
  `vote_id` int(11) NOT NULL,
  `question_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `vote_type` enum('up','down') NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `question_votes`
--

INSERT INTO `question_votes` (`vote_id`, `question_id`, `user_id`, `vote_type`, `created_at`) VALUES
(1, 1, 2, 'up', '2026-04-16 06:54:11'),
(2, 2, 1, 'up', '2026-04-16 06:54:11'),
(3, 3, 1, 'up', '2026-04-16 06:54:11'),
(4, 4, 3, 'up', '2026-04-16 06:54:11'),
(5, 5, 2, 'up', '2026-04-16 06:54:11'),
(6, 6, 1, 'up', '2026-04-16 06:54:11');

--
-- Triggers `question_votes`
--
DELIMITER $$
CREATE TRIGGER `remove_question_vote` AFTER DELETE ON `question_votes` FOR EACH ROW BEGIN
    UPDATE questions SET 
        upvotes = (SELECT COUNT(*) FROM question_votes WHERE question_id = OLD.question_id AND vote_type = 'up'),
        downvotes = (SELECT COUNT(*) FROM question_votes WHERE question_id = OLD.question_id AND vote_type = 'down')
    WHERE question_id = OLD.question_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_question_downvotes` AFTER INSERT ON `question_votes` FOR EACH ROW BEGIN
    UPDATE questions SET 
        downvotes = (SELECT COUNT(*) FROM question_votes WHERE question_id = NEW.question_id AND vote_type = 'down')
    WHERE question_id = NEW.question_id;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `update_question_upvotes` AFTER INSERT ON `question_votes` FOR EACH ROW BEGIN
    UPDATE questions SET 
        upvotes = (SELECT COUNT(*) FROM question_votes WHERE question_id = NEW.question_id AND vote_type = 'up')
    WHERE question_id = NEW.question_id;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `reports`
--

CREATE TABLE `reports` (
  `report_id` int(11) NOT NULL,
  `reported_item_type` enum('question','answer','user') NOT NULL,
  `reported_item_id` int(11) NOT NULL,
  `reporter_id` int(11) NOT NULL,
  `reason` enum('spam','inappropriate','harassment','copyright','off_topic','other') NOT NULL,
  `description` text DEFAULT NULL,
  `status` enum('pending','reviewed','resolved','dismissed') DEFAULT 'pending',
  `reviewed_by` int(11) DEFAULT NULL,
  `reviewed_at` timestamp NULL DEFAULT NULL,
  `review_notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(50) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `first_name` varchar(50) NOT NULL,
  `last_name` varchar(50) NOT NULL,
  `role` enum('user','admin','moderator') DEFAULT 'user',
  `level` int(11) DEFAULT 1,
  `profile_picture` varchar(255) DEFAULT NULL,
  `bio` text DEFAULT NULL,
  `status` enum('active','inactive','suspended') DEFAULT 'active',
  `email_verified_at` timestamp NULL DEFAULT NULL,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`user_id`, `username`, `email`, `password`, `first_name`, `last_name`, `role`, `level`, `profile_picture`, `bio`, `status`, `email_verified_at`, `last_login_at`, `created_at`, `updated_at`) VALUES
(1, 'admin', 'admin@astuq.edu', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'User', 'admin', 2, NULL, NULL, 'active', NULL, NULL, '2026-04-16 06:42:35', '2026-04-16 06:54:11'),
(2, 'john_doe', 'john@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'John', 'Doe', 'user', 3, NULL, NULL, 'active', NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(3, 'jane_smith', 'jane@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Jane', 'Smith', 'user', 2, NULL, NULL, 'active', NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11'),
(4, 'mike_wilson', 'mike@example.com', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Mike', 'Wilson', 'user', 1, NULL, NULL, 'active', NULL, NULL, '2026-04-16 06:54:11', '2026-04-16 06:54:11');

-- --------------------------------------------------------

--
-- Table structure for table `user_levels`
--

CREATE TABLE `user_levels` (
  `level_id` int(11) NOT NULL,
  `level` int(11) NOT NULL,
  `title` varchar(100) NOT NULL,
  `min_points` int(11) NOT NULL,
  `max_points` int(11) DEFAULT NULL,
  `badge_url` varchar(255) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_levels`
--

INSERT INTO `user_levels` (`level_id`, `level`, `title`, `min_points`, `max_points`, `badge_url`, `created_at`) VALUES
(1, 1, 'Beginner', 0, 99, NULL, '2026-04-16 06:42:35'),
(2, 2, 'Novice', 100, 299, NULL, '2026-04-16 06:42:35'),
(3, 3, 'Intermediate', 300, 699, NULL, '2026-04-16 06:42:35'),
(4, 4, 'Advanced', 700, 1499, NULL, '2026-04-16 06:42:35'),
(5, 5, 'Expert', 1500, 2999, NULL, '2026-04-16 06:42:35'),
(6, 6, 'Master', 3000, 5999, NULL, '2026-04-16 06:42:35'),
(7, 7, 'Grandmaster', 6000, 9999, NULL, '2026-04-16 06:42:35'),
(8, 8, 'Legend', 10000, NULL, NULL, '2026-04-16 06:42:35');

-- --------------------------------------------------------

--
-- Table structure for table `user_points`
--

CREATE TABLE `user_points` (
  `point_id` int(11) NOT NULL,
  `user_id` int(11) NOT NULL,
  `points` int(11) DEFAULT 0,
  `reason` enum('question_posted','answer_posted','best_answer','vote_received','daily_login','achievement') NOT NULL,
  `reference_id` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Dumping data for table `user_points`
--

INSERT INTO `user_points` (`point_id`, `user_id`, `points`, `reason`, `reference_id`, `created_at`) VALUES
(1, 1, 10, 'question_posted', NULL, '2026-04-16 06:54:11'),
(2, 1, 5, 'answer_posted', NULL, '2026-04-16 06:54:11'),
(3, 2, 10, 'question_posted', NULL, '2026-04-16 06:54:11'),
(4, 2, 5, 'best_answer', NULL, '2026-04-16 06:54:11'),
(5, 3, 10, 'question_posted', NULL, '2026-04-16 06:54:11'),
(6, 3, 5, 'answer_posted', NULL, '2026-04-16 06:54:11');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin_logs`
--
ALTER TABLE `admin_logs`
  ADD PRIMARY KEY (`log_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_action` (`action`),
  ADD KEY `idx_entity_type` (`entity_type`),
  ADD KEY `idx_entity_id` (`entity_id`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `answers`
--
ALTER TABLE `answers`
  ADD PRIMARY KEY (`answer_id`),
  ADD KEY `moderated_by` (`moderated_by`),
  ADD KEY `idx_question_id` (`question_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_is_best` (`is_best`),
  ADD KEY `idx_upvotes` (`upvotes`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `answer_votes`
--
ALTER TABLE `answer_votes`
  ADD PRIMARY KEY (`vote_id`),
  ADD UNIQUE KEY `unique_answer_vote` (`answer_id`,`user_id`),
  ADD KEY `idx_answer_id` (`answer_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_vote_type` (`vote_type`);

--
-- Indexes for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  ADD PRIMARY KEY (`token_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_expires_at` (`expires_at`);

--
-- Indexes for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD PRIMARY KEY (`bookmark_id`),
  ADD UNIQUE KEY `unique_bookmark` (`user_id`,`question_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_question_id` (`question_id`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_type` (`type`),
  ADD KEY `idx_is_read` (`is_read`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_priority` (`priority`);

--
-- Indexes for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD PRIMARY KEY (`reset_id`),
  ADD UNIQUE KEY `token` (`token`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_token` (`token`),
  ADD KEY `idx_expires_at` (`expires_at`);

--
-- Indexes for table `questions`
--
ALTER TABLE `questions`
  ADD PRIMARY KEY (`question_id`),
  ADD KEY `moderated_by` (`moderated_by`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_subject` (`subject`),
  ADD KEY `idx_category` (`category`),
  ADD KEY `idx_featured` (`featured`),
  ADD KEY `idx_created_at` (`created_at`),
  ADD KEY `idx_upvotes` (`upvotes`);
ALTER TABLE `questions` ADD FULLTEXT KEY `idx_search` (`title`,`content`);

--
-- Indexes for table `question_votes`
--
ALTER TABLE `question_votes`
  ADD PRIMARY KEY (`vote_id`),
  ADD UNIQUE KEY `unique_question_vote` (`question_id`,`user_id`),
  ADD KEY `idx_question_id` (`question_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_vote_type` (`vote_type`);

--
-- Indexes for table `reports`
--
ALTER TABLE `reports`
  ADD PRIMARY KEY (`report_id`),
  ADD KEY `reviewed_by` (`reviewed_by`),
  ADD KEY `idx_reported_item` (`reported_item_type`,`reported_item_id`),
  ADD KEY `idx_reporter_id` (`reporter_id`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD UNIQUE KEY `email` (`email`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_email` (`email`),
  ADD KEY `idx_role` (`role`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `user_levels`
--
ALTER TABLE `user_levels`
  ADD PRIMARY KEY (`level_id`),
  ADD UNIQUE KEY `level` (`level`),
  ADD KEY `idx_level` (`level`),
  ADD KEY `idx_min_points` (`min_points`);

--
-- Indexes for table `user_points`
--
ALTER TABLE `user_points`
  ADD PRIMARY KEY (`point_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_reason` (`reason`),
  ADD KEY `idx_created_at` (`created_at`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `admin_logs`
--
ALTER TABLE `admin_logs`
  MODIFY `log_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `answers`
--
ALTER TABLE `answers`
  MODIFY `answer_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `answer_votes`
--
ALTER TABLE `answer_votes`
  MODIFY `vote_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  MODIFY `token_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `bookmarks`
--
ALTER TABLE `bookmarks`
  MODIFY `bookmark_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `password_resets`
--
ALTER TABLE `password_resets`
  MODIFY `reset_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `questions`
--
ALTER TABLE `questions`
  MODIFY `question_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `question_votes`
--
ALTER TABLE `question_votes`
  MODIFY `vote_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `reports`
--
ALTER TABLE `reports`
  MODIFY `report_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT for table `user_levels`
--
ALTER TABLE `user_levels`
  MODIFY `level_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT for table `user_points`
--
ALTER TABLE `user_points`
  MODIFY `point_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `admin_logs`
--
ALTER TABLE `admin_logs`
  ADD CONSTRAINT `admin_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `answers`
--
ALTER TABLE `answers`
  ADD CONSTRAINT `answers_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`question_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `answers_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `answers_ibfk_3` FOREIGN KEY (`moderated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `answer_votes`
--
ALTER TABLE `answer_votes`
  ADD CONSTRAINT `answer_votes_ibfk_1` FOREIGN KEY (`answer_id`) REFERENCES `answers` (`answer_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `answer_votes_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `auth_tokens`
--
ALTER TABLE `auth_tokens`
  ADD CONSTRAINT `auth_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `bookmarks`
--
ALTER TABLE `bookmarks`
  ADD CONSTRAINT `bookmarks_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `bookmarks_ibfk_2` FOREIGN KEY (`question_id`) REFERENCES `questions` (`question_id`) ON DELETE CASCADE;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `notifications_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `password_resets`
--
ALTER TABLE `password_resets`
  ADD CONSTRAINT `password_resets_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `questions`
--
ALTER TABLE `questions`
  ADD CONSTRAINT `questions_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `questions_ibfk_2` FOREIGN KEY (`moderated_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `question_votes`
--
ALTER TABLE `question_votes`
  ADD CONSTRAINT `question_votes_ibfk_1` FOREIGN KEY (`question_id`) REFERENCES `questions` (`question_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `question_votes_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `reports`
--
ALTER TABLE `reports`
  ADD CONSTRAINT `reports_ibfk_1` FOREIGN KEY (`reporter_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `reports_ibfk_2` FOREIGN KEY (`reviewed_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `user_points`
--
ALTER TABLE `user_points`
  ADD CONSTRAINT `user_points_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
