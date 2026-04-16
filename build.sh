#!/bin/bash
set -e

DEFINES=""
for VAR in SUPABASE_URL SUPABASE_ANON_KEY GEMINI_API_KEY \
           GIPHY_API_KEY IPINFO_API_KEY ABSTRACT_API_KEY HUGGINGFACE_KEY \
           STREAM_CHAT_API_KEY CLOUDINARY_CLOUD_NAME CLOUDINARY_UPLOAD_PRESET \
           GOOGLE_MAPS_API_KEY; do
  VAL=$(eval echo \$$VAR)
  if [ -n "$VAL" ]; then
    DEFINES="$DEFINES --dart-define=$VAR=$VAL"
  fi
done

flutter/bin/flutter build web --release --no-tree-shake-icons $DEFINES
