# San Diego Institute of Technology

Public website for [sandiegotech.org](https://sandiegotech.org) — a founding institution for education in the age of AI.

## Structure

```
/                   Homepage and policy pages
/tools/             Five tool landing pages (Focus, Gloss, Scope, Shade, Gallery)
/papers/            Published papers and essays
/assets/            Brand assets — logos, icons, favicons
styles.css          Single global stylesheet
```

## Key pages

| Page | URL | Purpose |
|------|-----|---------|
| index.html | / | Founding Charter |
| philosophy.html | /philosophy | The Philosophy (14 tenets) |
| brand.html | /brand | Design system reference |
| legal.html | /legal | Legal structure and compliance |
| daily.html | /daily | The Daily email |
| apply.html | /apply | Join / Fellowship |

## Development

Served locally with Node — no build step.

```bash
node .claude/serve.mjs   # http://localhost:5500
```

## Deployment

GitHub Pages via the `main` branch. Custom domain: `sandiegotech.org` (set in `CNAME`).

## Internal docs

The `backstage/` folder is gitignored and has its own private repo at [sandiegotech/internal](https://github.com/sandiegotech/internal). It contains the founder's bible, build plan, and operational overview.
