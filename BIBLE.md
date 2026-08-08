# THE WEBSITE BIBLE

**What it is.** The public website for [sandiegotech.org](https://sandiegotech.org) — the San Diego Institute of Technology. Hand-written HTML and one stylesheet, no build step, no framework, no third-party requests. The Founding Charter is the homepage; the Philosophy, the Daily, and the application pages hang off it.

**Where it lives.** Repo `sandiegotech/website`. Served from **S3 behind CloudFront** — stack `sdit-apex-web` in `us-west-2` — with Cloudflare proxying DNS for the apex and `www`. Deploy by pushing to `main`.

---

## I. THE LAWS

### I-a. The site loads nothing from anyone else

Fonts are self-hosted in `assets/fonts/`. There is no CDN, no font service, no analytics script beyond Cloudflare Web Analytics, which is disclosed rather than hidden. An institution that teaches privacy does not leak its readers to third parties on the way in.

### I-b. `deploy.sh` publishes the working tree, not the git tree (2026-08-05)

This is the sharpest edge in the repo. `aws s3 sync` walks the folder on disk. **`.gitignore` has no bearing on it.** Anything sitting in the directory is published whether committed or not.

`backstage/` and `.claude/` are excluded *by name* in the script for exactly this reason. Any new private directory must be added to that exclusion list explicitly — assuming git will protect it is how private material gets published.

### I-c. CI can deploy the site; only a workstation can change infrastructure (2026-08-05)

The GitHub Actions role is assumed over GitHub's OIDC provider, so **no AWS keys are stored in the repo**. That role can read stack outputs and sync the site. It deliberately *cannot* alter infrastructure.

Changes to `infra/template.yaml` are therefore not applied by CI. Run the full `./infra/deploy.sh` from a workstation for those, and don't be surprised when a pushed template change appears to do nothing.

| Stack | What it holds |
|---|---|
| `sdit-apex-web` | Bucket, distribution, edge function, TLS |
| `sdit-github-oidc` | OIDC provider and the CI deploy role |

### I-d. The CloudFront function replaces what GitHub Pages gave for free (2026-08-05)

GitHub Pages served this domain until the cutover on 2026-08-05 and is no longer in the path. Two behaviors it provided are now done by the edge function in `infra/template.yaml`:

- redirecting `www` to the apex, and
- resolving extensionless paths like `/philosophy` and `/papers/` to the right object.

New **directories** are picked up automatically when linked with a trailing slash. Add one to the `DIRS` list only if the extensionless form also needs to work.

### I-e. The backstage is a different repo

`backstage/` is gitignored here and lives privately at `sandiegotech/internal` — the founder's bible, the build plan, and the operational overview. Public repo, public content. Nothing operational ships in this one.

### I-f. Claim only what the Institute can back (2026-07)

An honesty pass removed claims the Institute could not yet support, and the accreditation and non-discrimination pages exist to be accurate rather than impressive. When in doubt, say the smaller true thing. The hero has been rewritten several times toward this: lead with who it is for and what the days are actually like, not with the identity.

---

## II. HOW IT RUNS

Local, no build step:

```bash
node .claude/serve.mjs   # http://localhost:5500
```

Deploy — push to `main`, or from a workstation:

```bash
./infra/deploy.sh          # infrastructure + site
./infra/deploy.sh --site   # site only, identical to CI
```

`--site` regenerates the sitemap (`infra/build_sitemap.py`), syncs the tree, and invalidates the edge.

```
/                   Homepage and policy pages
/papers/            Published papers and essays
/research/          Lectio — the Institute's research project
/assets/            Brand assets; /assets/fonts/ self-hosted webfonts
/infra/             CloudFormation stack, deploy script, sitemap generator
styles.css          Single global stylesheet
```

| Page | URL | Purpose |
|---|---|---|
| `index.html` | `/` | Founding Charter |
| `philosophy.html` | `/philosophy` | The Philosophy — 12 tenets, 3 parts |
| `daily.html` | `/daily` | The Daily email |
| `apply.html` | `/apply` | Join / Fellowship |

---

## III. WHERE IT IS

Live and stable. The S3/CloudFront cutover landed 2026-08-05 and GitHub Pages is out of the path. Recent work has been on the homepage hero and an honesty pass over the claims; the last change was *"Hero: undivided, and work that lives in the world."*

Open: the Definition of done was never written down, and the tenets on `/philosophy` are ahead of the pages that are supposed to demonstrate them.
