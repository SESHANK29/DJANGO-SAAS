#!/bin/bash
set -e  # exit immediately if any command fails

echo "🚀 Starting build..."

# 1. Upgrade pip & install dependencies
python3 -m pip install --upgrade pip
python3 -m pip install -r requirements.txt

# 2. Collect static files for Django
echo "📦 Collecting static files..."
python3 manage.py collectstatic --noinput

# 3. Decode Firebase credentials
echo "🔑 Handling Firebase credentials..."
if [ -z "$FIREBASE_ENCODED" ]; then
    echo "❌ Error: FIREBASE_ENCODED environment variable is not set."
    exit 1
fi

python3 - <<'EOF'
import base64, json, sys, os

encoded_text = os.getenv("FIREBASE_ENCODED")
output_file = "project/firebase-cred.json"

try:
    decoded_bytes = base64.b64decode(encoded_text)
    decoded_text = decoded_bytes.decode("utf-8")
    print(f"📄 Decoded JSON length: {len(decoded_text)} chars")
    json_data = json.loads(decoded_text)
except Exception as e:
    print(f"❌ Error decoding Firebase credentials: {e}", file=sys.stderr)
    sys.exit(1)

os.makedirs(os.path.dirname(output_file), exist_ok=True)

try:
    with open(output_file, "w") as f:
        json.dump(json_data, f, indent=4)
    print(f"✅ Firebase credentials written to {output_file}")
except IOError as e:
    print(f"❌ Error writing JSON file: {e}", file=sys.stderr)
    sys.exit(1)
EOF

# 4. Build Tailwind CSS
if [ -f "tailwind.config.js" ]; then
    if ! command -v npx &> /dev/null; then
        echo "❌ npx not found. Install Node.js first."
        exit 1
    fi
    echo "🎨 Building Tailwind CSS..."
    npx tailwindcss -i ./theme/static_src/input.css -o ./theme/static/dist/output.css --minify
fi

echo "✅ Build completed successfully!"
