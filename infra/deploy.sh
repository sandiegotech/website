#!/usr/bin/env bash
# Deploy sandiegotech.org — stack, then site, then cache invalidation.
#
# Safe to run before DNS is cut over: until the Cloudflare records point at
# CloudFront, this publishes to the distribution's own *.cloudfront.net address
# and GitHub Pages keeps serving the live domain. Verify there first.
#
#   ./deploy.sh            # stack + site
#   ./deploy.sh --site     # site only (skip the CloudFormation step)
set -euo pipefail

STACK=sdit-apex-web
REGION=us-west-2
DOMAIN=sandiegotech.org
CERT_ARN=arn:aws:acm:us-east-1:681432799403:certificate/59fb1783-88f3-4e97-a036-a48abcf4679b

cd "$(dirname "$0")"
SITE_ROOT="$(cd .. && pwd)"

if [ "${1:-}" != "--site" ]; then
  echo "→ Deploying stack $STACK"
  aws cloudformation deploy \
    --template-file template.yaml \
    --stack-name "$STACK" \
    --region "$REGION" \
    --no-fail-on-empty-changeset \
    --parameter-overrides \
      DomainName="$DOMAIN" \
      CertificateArn="$CERT_ARN"
fi

# Derived from disk rather than maintained by hand: a page added without a
# sitemap entry, or edited without touching its lastmod, would otherwise ship
# a sitemap that disagrees with the site. Both had happened.
echo "→ Regenerating sitemap"
python3 ./build_sitemap.py

# Look each output up by name. A single multi-key query returns them in
# CloudFormation's order, not the order they were asked for, so positional
# reads silently assign the wrong value to the wrong variable.
stack_output() {
  aws cloudformation describe-stacks \
    --stack-name "$STACK" --region "$REGION" \
    --query "Stacks[0].Outputs[?OutputKey=='$1'].OutputValue" --output text
}

BUCKET=$(stack_output BucketName)
DIST_ID=$(stack_output DistributionId)
DIST_DOMAIN=$(stack_output DistributionDomain)

for v in BUCKET DIST_ID DIST_DOMAIN; do
  if [ -z "${!v}" ]; then echo "error: stack output for $v is empty" >&2; exit 1; fi
done

echo "→ Syncing site to s3://$BUCKET"
# --delete keeps the bucket an exact mirror of the repo, so a page removed here
# disappears from the site. Excludes are repo metadata, not site content —
# CNAME in particular is a GitHub Pages artifact that means nothing to S3.
#
# This syncs the WORKING TREE, not the git tree: anything sitting in the folder
# gets published whether or not it is committed. backstage/ and .claude/ are
# gitignored precisely because they must never be public, so they are excluded
# by name here too — .gitignore has no effect on `aws s3 sync`.
aws s3 sync "$SITE_ROOT" "s3://$BUCKET" \
  --delete \
  --exclude ".git/*" \
  --exclude ".github/*" \
  --exclude ".claude/*" \
  --exclude "backstage/*" \
  --exclude ".gitattributes" \
  --exclude ".gitignore" \
  --exclude ".DS_Store" \
  --exclude "*/.DS_Store" \
  --exclude "infra/*" \
  --exclude "CNAME" \
  --exclude "*.md"

# HTML is cached at the edge under the CachingOptimized policy, so a sync alone
# would leave stale pages served for hours. "/*" counts as ONE path against the
# 1,000-per-month free allowance, not one per file.
echo "→ Invalidating CloudFront cache"
aws cloudfront create-invalidation \
  --distribution-id "$DIST_ID" --paths "/*" \
  --query 'Invalidation.Id' --output text

echo
echo "Done. Test at:  https://$DIST_DOMAIN"
echo "Live domain ($DOMAIN) is unchanged until DNS is cut over."
