#!/usr/bin/env python3
"""Regenerate sitemap.xml from what is actually on disk.

Hand-maintained sitemaps drift twice: pages get added without an entry, and
lastmod dates keep whatever was typed when the file was created. Both happened.
This derives the URL list from the .html files present and the dates from git,
so the sitemap cannot disagree with the site.

Excluded: 404, anything carrying <meta name="robots" content="noindex">, and
the repo's non-published directories.

Run from anywhere; deploy.sh calls it before syncing.
"""
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BASE = "https://sandiegotech.org"
SKIP_DIRS = {"assets", "infra", ".git", ".github", "backstage", ".claude"}
SKIP_FILES = {"404.html"}

# Pages worth ranking above the default. Everything else gets 0.5/monthly.
WEIGHTS = {
    "": (1.0, "weekly"),
    "academics.html": (0.9, "monthly"),
    "philosophy.html": (0.9, "monthly"),
    "apply.html": (0.8, "monthly"),
    "daily.html": (0.8, "daily"),
    "papers/": (0.8, "weekly"),
    "research/": (0.8, "weekly"),
    "fellowship.html": (0.7, "monthly"),
    "student.html": (0.7, "monthly"),
    "accreditation.html": (0.7, "monthly"),
    "support.html": (0.6, "monthly"),
    "people.html": (0.6, "monthly"),
}


def git_date(path: Path) -> str:
    """Last commit date for a file, or today if it is not committed yet."""
    out = subprocess.run(
        ["git", "log", "-1", "--format=%ad", "--date=short", "--", str(path)],
        cwd=ROOT, capture_output=True, text=True,
    ).stdout.strip()
    if out:
        return out
    return subprocess.run(
        ["git", "log", "-1", "--format=%ad", "--date=short"],
        cwd=ROOT, capture_output=True, text=True,
    ).stdout.strip()


def is_noindex(path: Path) -> bool:
    head = path.read_text(errors="ignore")[:4000]
    return bool(re.search(r'<meta\s+name="robots"[^>]*noindex', head, re.I))


def url_for(rel: Path) -> str:
    """Clean URL: index.html becomes its directory, other pages keep .html."""
    if rel.name == "index.html":
        parent = str(rel.parent)
        return "" if parent == "." else f"{parent}/"
    return str(rel)


def main() -> None:
    pages = []
    for p in sorted(ROOT.rglob("*.html")):
        rel = p.relative_to(ROOT)
        if rel.parts[0] in SKIP_DIRS or rel.name in SKIP_FILES:
            continue
        if is_noindex(p):
            continue
        pages.append((url_for(rel), git_date(p)))

    # Highest priority first, then alphabetically, so the file reads sensibly.
    pages.sort(key=lambda e: (-WEIGHTS.get(e[0], (0.5, ""))[0], e[0]))

    lines = ['<?xml version="1.0" encoding="UTF-8"?>',
             '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
    for slug, date in pages:
        priority, freq = WEIGHTS.get(slug, (0.5, "monthly"))
        lines += ["  <url>",
                  f"    <loc>{BASE}/{slug}</loc>",
                  f"    <lastmod>{date}</lastmod>",
                  f"    <changefreq>{freq}</changefreq>",
                  f"    <priority>{priority}</priority>",
                  "  </url>"]
    lines.append("</urlset>")

    (ROOT / "sitemap.xml").write_text("\n".join(lines) + "\n")
    print(f"sitemap.xml: {len(pages)} urls")


if __name__ == "__main__":
    main()
