# Photo Puzzles — add your own images

This folder feeds the **Photo Puzzles** section in the game. To add a photo:

1. **Drop your image file here** (JPG or PNG — portrait 3:4 crops best,
   any size works; the game scales it down).
2. **Add one entry to `manifest.json`**, either a local file:

   ```json
   { "id": "my_photo_1", "title": "My Photo", "image": "assets/images/photos/my_photo_1.jpg" }
   ```

   or an internet image:

   ```json
   { "id": "web_1", "title": "Web Photo", "url": "https://example.com/photo.jpg" }
   ```

3. **Rebuild the app** — the photo appears in Photo Puzzles immediately.

Rules:
- `id` must be unique and lowercase-with-dashes.
- `title` is what players see.
- Use `image` for files in this folder, `url` for internet images — pick one.
- The default entries point at bundled photos from
  `assets/images/collections/` so the section ships no third-party
  imagery and works offline; replace or delete them whenever you like.
- Photo Puzzles is disabled in the shipped build via
  `AppConfig.photoPuzzlesEnabled` — flip that flag to surface it.
