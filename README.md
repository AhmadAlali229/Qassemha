# Qassemha (Dev Notes)

## Groq parser local setup (dev only)
- The scan flow now uses Groq to parse OCR text into receipt items/totals.
- Provide the API key locally in one of these ways:
  - Set `GROQ_API_KEY` in your Xcode Run scheme environment variables, or
  - Create `Qassemha/Config/GroqConfig.local.plist` with:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GROQ_API_KEY</key>
    <string>YOUR_KEY_HERE</string>
</dict>
</plist>
```

- `GroqConfig.local.plist` is git-ignored and must not be committed.
