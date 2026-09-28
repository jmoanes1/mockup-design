# Grip op China · Yu Shan Management — website redesign mockup

A static, high-fidelity three-page redesign proposal for **Grip op China / Yu Shan
Management** (gripopchina.nl): a Dutch-run consultancy and interim-management firm
for Dutch companies doing business in China, operating from Hong Kong.

Everything is plain HTML + CSS (+ ~90 lines of vanilla JS for the header, mobile
navigation, scroll reveals and footer year). No build step, no framework, no
tracking code, no external dependency except the Inter webfont from Google Fonts.

## Pages

| File | Purpose |
| --- | --- |
| `index.html` | Home: hero, key figures, "Praktische ondersteuning in China", services (Consultancy + Interim Management), working method, 21 sectors, contact CTA |
| `projecten.html` | Projects: approach, cities, nine practice-area cards, "Zo werken wij" commitments, working method, contact CTA |
| `yushanmanagement-contact.html` | Yu Shan Management story, team & quality, contact details, contact form, location map |

Open `index.html` directly in a browser, or serve the folder locally
(`npx serve .`, `python -m http.server`) and browse to it.

## Design system

* `assets/css/styles.css` — single stylesheet: design tokens, base/reset,
  typography, buttons, header + mobile navigation, hero, fact bar, editorial
  figures, cards, pills, numbered commitments, CTA band, contact form, footer and
  the responsive breakpoints (1240 / 1080 / 980 / 720 px).
* Palette: paper white, warm off-white (`--sand`), charcoal (`--ink`) and a single
  brand red accent (`--accent: #b01218`) taken from the logo.
* Type: Inter, editorial scale via `clamp()`; uppercase tracked labels as accents.
* The brand lockup in the header and footer is rebuilt from the real logo
  ("GRIP OP CHINA ▸ YU SHAN MANAGEMENT" with the red Y mark) as inline SVG, so it
  stays crisp at any size. The original artwork is kept in
  `assets/img/_src-logo.jpg`.
* Accessibility: skip link, visible focus rings, `aria-current` on the active nav
  item, labelled form fields, `prefers-reduced-motion` support, semantic
  landmarks, and a no-JS fallback (the reveal animation is opt-in via a `.js`
  class).

## Content and photography

* All copy is derived from the current live website (home, Consultancy + Interim
  Management, Projecten, Yu Shan Management + Contact) and from archived pages of
  the same site (working-way commitments, cities, specialisms). Nothing about the
  company's services, address, e-mail or phone number has been invented.
* Client and logo names from the live "Projecten" page are intentionally **not**
  reproduced; the projects section describes practice areas instead and says so in
  a visible note.
* Photography comes from Wikimedia Commons and Pexels (free licences) — see
  `assets/img/CREDITS.md`. The live site only uses thin banner strips, so stock
  imagery is used to show what the redesign could look like.

## Tooling (`tools/`)

| Script | Purpose |
| --- | --- |
| `fetch-final-images.ps1` | Downloads the final photography at usable resolution into `assets/img/`, validates the JPEG/PNG responses, caps the width at 1800 px and re-encodes everything at a web-friendly quality. Re-runnable. |
| `screenshot.ps1` | Renders a page in headless Chrome (or Edge) and slices the screenshot into JPEG bands in `assets/_review/` for visual review. `-Mobile` switches to a 500 px viewport; `--force-prefers-reduced-motion` is passed so screenshots are deterministic. |
| `review-images.ps1` | Earlier exploration step: downloads a large candidate pool at preview size and builds a labelled contact sheet (`assets/_review/sheet.png`) to choose images from. |

Run them from the project root, e.g.:

```powershell
powershell -ExecutionPolicy Bypass -File tools\fetch-final-images.ps1
powershell -ExecutionPolicy Bypass -File tools\screenshot.ps1 -Page index.html -Height 6600 -Bands 6
```

## Limitations (mockup, not production)

* The contact form has no backend: submitting shows a note instead of sending
  anything. Point it at a real endpoint (or a form service) before going live.
* No analytics, cookie banner or CMS integration; pages are hand-authored.
* The phone number is reproduced exactly as published on the live site.
* Images are third-party stock under free licences; a production build should use
  the client's own photography where available.
* `assets/_review/` holds working files (contact sheets, screenshots) and can be
  deleted without affecting the mockup.
