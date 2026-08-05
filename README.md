# San Diego Institute of Technology

Public website for [sandiegotech.org](https://sandiegotech.org) — a founding institution for education in the age of AI.

GitHub: [sandiegotech/website](https://github.com/sandiegotech/website)

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
| daily.html | /daily | The Daily email |
| apply.html | /apply | Join / Fellowship |

## Development

Served locally with Node — no build step.

```bash
node .claude/serve.mjs   # http://localhost:5500
```

## Deployment

Push to `main`. The **Deploy site** workflow syncs the repo to S3 and invalidates
the CloudFront cache; it authenticates by assuming an AWS role over GitHub's OIDC
provider, so there are no AWS keys stored in the repo.

To publish from a workstation instead — or to apply an infrastructure change,
which the CI role deliberately cannot do:

```bash
./infra/deploy.sh          # infrastructure + site
./infra/deploy.sh --site   # site only, same as CI
```

Note that `deploy.sh` syncs the **working tree**, not the git tree — anything
sitting in the folder is published whether committed or not. `backstage/` and
`.claude/` are excluded by name for that reason; `.gitignore` has no bearing on
`aws s3 sync`.

### Hosting

Mid-migration. The live domain is still served by **GitHub Pages** (custom domain
in `CNAME`), fronted by Cloudflare. The replacement — S3 behind CloudFront,
stack `sdit-apex-web` in `us-west-2` — is built, populated, and verified at its
distribution address, but DNS has not been cut over.

The last step is repointing `sandiegotech.org` and `www` at the distribution in
Cloudflare DNS, set to **DNS only**. Until then the workflow publishes to a
bucket nobody is reading, which is harmless. Rollback after cutover is restoring
the previous Cloudflare records.

| Stack | What it holds |
|-------|---------------|
| `sdit-apex-web` | Bucket, distribution, edge function, TLS |
| `sdit-github-oidc` | OIDC provider and the CI deploy role |

Two things GitHub Pages did for free are handled by the CloudFront function in
`infra/template.yaml`: redirecting `www` to the apex, and resolving `/philosophy`
and `/papers/` to the right objects. New **directories** are picked up
automatically when linked with a trailing slash; add them to the `DIRS` list only
if the extensionless form needs to work too.

## Internal docs

The `backstage/` folder is gitignored and has its own private repo at [sandiegotech/internal](https://github.com/sandiegotech/internal). It contains the founder's bible, build plan, and operational overview.
