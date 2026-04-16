-- Set Marc.H.Mercury@gmail.com as the only admin
-- First, remove admin from all other users
UPDATE public.profiles SET is_admin = FALSE WHERE is_admin = TRUE;

-- Then set admin for Marc by matching email in auth.users
UPDATE public.profiles
SET is_admin = TRUE
WHERE id = (
  SELECT id FROM auth.users
  WHERE LOWER(email) = LOWER('Marc.H.Mercury@gmail.com')
  LIMIT 1
);

-- Ensure Marc's membership_status is approved
UPDATE public.profiles
SET membership_status = 'approved'
WHERE id = (
  SELECT id FROM auth.users
  WHERE LOWER(email) = LOWER('Marc.H.Mercury@gmail.com')
  LIMIT 1
);
