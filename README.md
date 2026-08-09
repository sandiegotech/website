# San Diego Institute of Technology

Public website for [sandiegotech.org](https://sandiegotech.org) — a new institution where engineers and creative people work together to make beautiful things.

GitHub: [sandiegotech/website](https://github.com/sandiegotech/website)

## Structure

```
/                   Homepage and policy pages
/papers/            Published papers and essays
/lectio/            Lectio — the Institute's first project
/assets/            Brand assets — logos, icons, favicons
/assets/fonts/      Self-hosted webfonts (the site loads nothing third-party)
/infra/             CloudFormation stack, deploy script, sitemap generator
styles.css          Single global stylesheet
```

## Key pages

| Page | URL | Purpose |
|------|-----|---------|
| index.html | / | Founding Charter |
| philosophy.html | /philosophy | The Philosophy (12 tenets, 3 parts) |
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

Served from **S3 behind CloudFront** (stack `sdit-apex-web`, `us-west-2`),
with Cloudflare proxying DNS for the apex and `www`. GitHub Pages served this
domain until the cutover on 2026-08-05 and is no longer in the path.

Pushing to `main` deploys: the workflow assumes an OIDC role and runs
`./infra/deploy.sh --site`, which regenerates the sitemap, syncs the tree, and
invalidates the edge. Changes to `infra/template.yaml` are **not** applied by
CI — the deploy role can read stack outputs but cannot alter infrastructure —
so run the full `./infra/deploy.sh` from a workstation for those.

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

## Rights

Code in this repository is MIT-licensed; the site's prose, the papers, and
the artwork are CC BY-NC 4.0 — free to share and teach from with credit,
commercial rights reserved to the Institute. See [LICENSE.md](LICENSE.md).
