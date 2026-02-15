-- ============================================================
-- Kapsa Performance Indexes
-- Run this in Supabase SQL Editor (Dashboard > SQL Editor)
-- ============================================================

-- Courses: fast lookup by user + sort by created_at
CREATE INDEX IF NOT EXISTS idx_courses_user_created
  ON courses (user_id, created_at DESC);

-- Course Materials: fast lookup by course + sort by created_at
CREATE INDEX IF NOT EXISTS idx_materials_course_created
  ON course_materials (course_id, created_at DESC);

-- Course Materials: recent materials by user (for Home screen)
CREATE INDEX IF NOT EXISTS idx_materials_user_created
  ON course_materials (user_id, created_at DESC);

-- Chat Messages: fast lookup by session + chronological order
CREATE INDEX IF NOT EXISTS idx_chat_messages_session_created
  ON chat_messages (session_id, created_at DESC);

-- Chat Sessions: find session by course + user
CREATE INDEX IF NOT EXISTS idx_chat_sessions_course_user
  ON chat_sessions (course_id, user_id);

-- Flashcard Decks: fast lookup by course + sort by created_at
CREATE INDEX IF NOT EXISTS idx_flashcard_decks_course_created
  ON flashcard_decks (course_id, created_at DESC);

-- Flashcards: fast lookup by deck + sort by created_at
CREATE INDEX IF NOT EXISTS idx_flashcards_deck_created
  ON flashcards (deck_id, created_at ASC);

-- Tests: lookup by course
CREATE INDEX IF NOT EXISTS idx_tests_course_created
  ON tests (course_id, created_at DESC);

-- Test Questions: lookup by test
CREATE INDEX IF NOT EXISTS idx_test_questions_test
  ON test_questions (test_id, question_number ASC);
