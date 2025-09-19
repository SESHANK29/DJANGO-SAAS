#!/bin/bash

# 1. Install dependencies
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

# 2. Collect static files for Django
python3 manage.py collectstatic --noinput

# 3. Handle Firebase credentials from environment variable
if [ -z "$FIREBASE_ENCODED" ]; then
    echo "Error: FIREBASE_ENCODED environment variable is not set."
    exit 1
fi

output_file="project/firebase-cred.json"

python3 - <<EOF
import base64
import json
import sys

encoded_text = '''$FIREBASE_ENCODED'''

try:
    decoded_bytes = base64.b64decode(encoded_text)
    decoded_text = decoded_bytes.decode('utf-8')
    json_data = json.loads(decoded_text)
except Exception as e:
    print(f"Error decoding Firebase credentials: {e}", file=sys.stderr)
    sys.exit(1)

try:
    with open("$output_file", "w") as f:
        json.dump(json_data, f, indent=4)
    print(f"Firebase credentials written to {output_file}")
except IOError as e:
    print(f"Error writing JSON file: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# 4. Build Tailwind CSS (if using django-tailwind)
if [ -f "tailwind.config.js" ]; then
    echo "Building Tailwind CSS..."
    npx tailwindcss -i ./theme/static_src/input.css -o ./theme/static/dist/output.css --minify
fi
