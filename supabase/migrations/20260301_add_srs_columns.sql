-- ============================================================
-- Migration: Add Spaced Repetition (FSRS) support
-- Date: 2026-03-01
-- ============================================================

-- 1. Add SRS columns to flashcards table
ALTER TABLE public.flashcards
  ADD COLUMN IF NOT EXISTS stability double precision NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS difficulty double precision NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS elapsed_days integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS scheduled_days integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS reps integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS lapses integer NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS srs_state smallint NOT NULL DEFAULT 0,  -- 0=New, 1=Learning, 2=Review, 3=Relearning
  ADD COLUMN IF NOT EXISTS due timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS last_review timestamptz;

-- Index for fetching due cards efficiently
CREATE INDEX IF NOT EXISTS idx_flashcards_due
  ON public.flashcards (due)
  WHERE srs_state >= 0;

-- 2. Create card_reviews table (review log for analytics)
CREATE TABLE IF NOT EXISTS public.card_reviews (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  card_id uuid NOT NULL REFERENCES public.flashcards(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  rating smallint NOT NULL,         -- 1=Again, 2=Hard, 3=Good, 4=Easy
  state smallint NOT NULL,          -- srs_state BEFORE this review
  scheduled_days integer NOT NULL,
  elapsed_days integer NOT NULL,
  reviewed_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_card_reviews_card
  ON public.card_reviews(card_id);

CREATE INDEX IF NOT EXISTS idx_card_reviews_user_date
  ON public.card_reviews(user_id, reviewed_at DESC);

-- 3. Enable RLS on card_reviews
ALTER TABLE public.card_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own reviews"
  ON public.card_reviews FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own reviews"
  ON public.card_reviews FOR SELECT
  USING (auth.uid() = user_id);
