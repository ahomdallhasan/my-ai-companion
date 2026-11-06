# AI Romantic Companion — Complete Production-Ready Project

A private, minimal Bangla/Banglish AI Romantic Companion Android app built with Flutter and a secure Node.js/Express OpenAI backend.

## What Has Been Completed & Upgraded

1. **Complete Android Platform Configuration (`android/`)**:
   - Added `AndroidManifest.xml` (with `INTERNET` permission and local cleartext support for LAN testing), `build.gradle`, `settings.gradle`, `gradle.properties`, `MainActivity.kt`, styles, and launcher icons (`@mipmap/ic_launcher`).
2. **Automatic Long-Term Memory Extraction & Retrieval**:
   - The backend (`backend/server.js`) uses OpenAI Structured JSON output to return both the natural conversational `reply` and any newly discovered `extractedMemories` in a single API call.
   - New personal details, preferences, and shared moments are automatically deduplicated, merged, saved on the phone via `SharedPreferences`, and injected into future prompts.
   - A subtle floating notification appears in the chat whenever your companion remembers a new detail about you.
3. **Full Personality, Relationship & Pronoun Control**:
   - Customize your companion's **Name**, **Relationship Dynamic** (Girlfriend/Wife vibe, Loving Wife, Sweet Girlfriend, Caring Soulmate), and **Bengali Address Style** (`তুমি`, `তুই`, or `আপনি`).
   - One-tap personality presets + full custom Bangla/English personality prompt editor.
4. **Zero API Key Exposure in APK**:
   - Your `OPENAI_API_KEY` stays strictly on the backend (`backend/.env` or Vercel environment variables).
   - Added optional `APP_ACCESS_TOKEN` header authentication (`X-App-Token`) so your backend remains completely private.
   - Added an in-app **Backend URL & Connection Tester** in Settings so you never need to recompile the APK when switching between local Wi-Fi and a hosted Vercel URL.
5. **Cloud & Local APK Build Automation**:
   - Includes `.github/workflows/build_apk.yml` to compile and download `app-release.apk` directly on GitHub Actions even if you don't have Android Studio installed locally.

---

## Step 1: Run or Deploy the Secure Backend

### Option A: Run Locally (Computer / LAN)
1. Open a terminal in `backend/`:
   ```bash
   cd backend
   npm install
   ```
2. Copy `.env.example` to `.env` and fill in your OpenAI API key:
   ```env
   OPENAI_API_KEY=sk-proj-your_real_openai_key
   OPENAI_MODEL=gpt-4.1-mini
   PORT=3000
   APP_ACCESS_TOKEN=my_secret_companion_password
   ```
3. Start the server:
   ```bash
   npm start
   ```
4. Verify in your browser: `http://localhost:3000/health`

### Option B: Deploy to Vercel (Recommended for Standalone Phone Use Anywhere)
1. Push the `backend/` folder to a private GitHub repo or run `vercel` inside `backend/` (`vercel.json` is pre-configured).
2. In your Vercel Project Settings -> **Environment Variables**, add:
   - `OPENAI_API_KEY`
   - `OPENAI_MODEL` (`gpt-4.1-mini`)
   - `APP_ACCESS_TOKEN` (optional private password)
3. Copy your deployed Vercel URL (e.g., `https://my-companion-backend.vercel.app`) and paste it directly into the app's **Settings -> Backend URL** field.

---

## Step 2: Build the Release Android APK (`app-release.apk`)

*(Note: AI sandbox environments do not contain the 8 GB Android SDK/Gradle binary toolchain, so the final binary compilation step runs via Flutter CLI on your machine or automatically via the included GitHub Actions workflow.)*

### Method 1: Local Build on Your Computer
From the project root folder:
```bash
# Ensure local Gradle wrapper binaries are initialized
flutter create . --platforms=android

# Fetch packages
flutter pub get

# Build the release APK
flutter build apk --release
```
Your finished APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`

### Method 2: Zero-Setup Cloud Build via GitHub Actions
1. Push this project folder to a private GitHub repository.
2. Go to the **Actions** tab in your GitHub repository and select **Build Release Android APK**.
3. Click **Run workflow**.
4. In ~3 minutes, download `ai-romantic-companion-release-apk` containing `app-release.apk`.

---

## Step 3: How to Install the APK on Your Android Phone

1. Transfer `app-release.apk` to your Android phone (via USB cable, Google Drive, Telegram Saved Messages, or direct download from GitHub Actions).
2. Tap on `app-release.apk` on your phone.
3. If prompted with *"For your security, your phone currently isn't allowed to install unknown apps from this source"*, tap **Settings** and toggle on **Allow from this source**.
4. Tap **Install**, then **Open**.
5. If Android Play Protect shows an *"Unrecognized app developer"* prompt (normal for personal self-signed APKs), tap **More details -> Install anyway**.
6. Open the app, tap the **Settings (tune icon)** in the top-right corner, enter your **Backend URL** (your Vercel HTTPS URL or your computer's LAN IP like `http://192.168.1.5:3000`), tap **Test Backend Connection**, and start chatting!
