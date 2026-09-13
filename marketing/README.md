# Marketing assets

Roblox listing art, rendered from HTML with headless Chrome so it's easy to tweak:

```bash
"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --hide-scrollbars --window-size=1920,1080 --screenshot=thumbnail.png thumbnail.html
"C:\Program Files\Google\Chrome\Application\chrome.exe" --headless=new --disable-gpu --hide-scrollbars --window-size=512,512 --screenshot=icon.png icon.html
```

- `thumbnail.html` → `thumbnail.png` (1920x1080) — Creator Hub > Configure > Places > start place > Thumbnails
- `icon.html` → `icon.png` (512x512) — Creator Hub > Configure > Settings > Experience icon
