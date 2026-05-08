-- Migration script to add images column to questions table
-- Run this on your existing database to add the missing images column

USE astuq_database;

-- Add images column to questions table
ALTER TABLE questions ADD COLUMN images JSON NULL AFTER tags;

-- Verify the column was added
DESCRIBE questions;
