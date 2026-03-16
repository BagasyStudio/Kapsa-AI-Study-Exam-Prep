-- Add parent/child deck (subdeck) support
-- parent_deck_id: NULL = parent or legacy flat deck, NOT NULL = child subdeck
-- description: AI-generated summary of deck content
-- cover_gradient_index: 0-11, selects from curated gradient palette

ALTER TABLE public.flashcard_decks
  ADD COLUMN IF NOT EXISTS parent_deck_id uuid
    REFERENCES public.flashcard_decks(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS cover_gradient_index smallint NOT NULL DEFAULT 0;

-- Fast lookup of child decks for a parent
CREATE INDEX IF NOT EXISTS idx_flashcard_decks_parent
  ON public.flashcard_decks (parent_deck_id)
  WHERE parent_deck_id IS NOT NULL;

-- Fast lookup of root-level (parent) decks per course
CREATE INDEX IF NOT EXISTS idx_flashcard_decks_root_per_course
  ON public.flashcard_decks (course_id, created_at DESC)
  WHERE parent_deck_id IS NULL;
