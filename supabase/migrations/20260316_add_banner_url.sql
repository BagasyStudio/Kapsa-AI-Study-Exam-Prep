-- Add Pexels banner image URL for flashcard deck covers
ALTER TABLE public.flashcard_decks ADD COLUMN IF NOT EXISTS banner_url text;
