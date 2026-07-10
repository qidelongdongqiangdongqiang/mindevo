# Deployment Automation Setup

This document defines the remaining one-time setup for a complete GitHub-to-Aliyun deployment pipeline.

## What Is Automated After This Setup

After the GitHub settings below are in place:

1. Push to `main`
2. GitHub Actions runs internal link checks
3. GitHub Actions backs up the current production site on Aliyun
4. GitHub Actions uploads the new site files to `/var/www/mindevo`
5. GitHub Actions smoke-checks the live URLs
6. If OSS sync is enabled, GitHub Actions also uploads `assets/` to OSS

For staging:

1. Push to `staging`
2. GitHub Actions runs the same checks
3. GitHub Actions deploys to the staging web root
4. GitHub Actions smoke-checks the staging URLs

## GitHub Actions Added In This Repository

- `.github/workflows/site-checks.yml`
- `.github/workflows/deploy-production.yml`
- `.github/workflows/deploy-staging.yml`

The checks also validate WeChat share wiring:

- shareable pages include the WeChat JS-SDK loader
- canonical enrollment links do not regress to `index.html`
- the WeChat signature service files are present

## Required GitHub Secrets

Set these in the repository settings:

`Settings -> Secrets and variables -> Actions`

### Required now

- `DEPLOY_SSH_KEY`
  - value: the private key that matches the server's `deploy` user authorized key

### Required when OSS automation is enabled

- `OSS_ACCESS_KEY_ID`
- `OSS_ACCESS_KEY_SECRET`

### Required when WeChat share automation is enabled

- `WECHAT_APP_ID`
- `WECHAT_APP_SECRET`

## Required GitHub Variables

Set these in:

`Settings -> Secrets and variables -> Actions -> Variables`

### Production

- `PROD_DEPLOY_HOST = 121.40.130.19`
- `PROD_DEPLOY_USER = deploy`
- `PROD_WEB_ROOT = /var/www/mindevo`
- `PROD_URL = https://www.mindevo.club`

### OSS

- `OSS_BUCKET = mindevo-static`
- `OSS_ENDPOINT = oss-cn-hangzhou.aliyuncs.com`
- `OSS_REGION = cn-hangzhou`
- `OSS_SYNC_ENABLED = false`

Set `OSS_SYNC_ENABLED = true` only after OSS credentials are configured and tested.

### WeChat Share

- `WECHAT_SHARE_ENABLED = false`

Set `WECHAT_SHARE_ENABLED = true` only after:

1. the ECS root setup in `docs/wechat-share-automation.md` has been completed
2. the WeChat Official Account JS interface security domain includes `www.mindevo.club`
3. `WECHAT_APP_ID` and `WECHAT_APP_SECRET` have been added as GitHub Actions secrets

### Staging

- `STAGING_DEPLOY_HOST = 121.40.130.19`
- `STAGING_DEPLOY_USER = deploy`
- `STAGING_WEB_ROOT = /var/www/mindevo-staging`
- `STAGING_URL = https://staging.mindevo.club`

## Why OSS Is Guarded

This site already serves most CSS, images, and `site.js` from OSS.

That means:

- HTML, `robots.txt`, `sitemap.xml`, `404.html`, `assets/js/analytics.js`, and `assets/js/tracking-config.js` can deploy correctly without OSS sync
- CSS, images, and other OSS-backed assets must be uploaded to OSS, or production will not reflect those changes

The production workflow therefore fails on purpose if:

- an OSS-backed file changed, and
- `OSS_SYNC_ENABLED` is not `true`

This is intentional. Silent partial deploys are worse than a blocked deploy.

## One-Time Aliyun Setup For OSS

Create a dedicated RAM user for GitHub Actions.

Recommended policy scope:

- only the `mindevo-static` bucket
- only object read/write needed for `/assets/*`

After creating the RAM user:

1. generate an AccessKey pair
2. store it in GitHub secrets:
   - `OSS_ACCESS_KEY_ID`
   - `OSS_ACCESS_KEY_SECRET`
3. set `OSS_SYNC_ENABLED = true`
4. push a small CSS or image change to confirm OSS sync works

Do not use the root Alibaba Cloud account AccessKey for GitHub Actions.

## One-Time Aliyun Setup For Staging

Staging is prepared in code, but it still needs one root-level server setup.

The `deploy` user does not currently have permission to:

- create `/var/www/mindevo-staging`
- write `/etc/nginx`

So staging needs:

1. DNS record
   - `staging.mindevo.club -> 121.40.130.19`
2. server directories
   - `/var/www/mindevo-staging`
   - `/var/www/mindevo-staging-backups`
3. ownership
   - `deploy:deploy`
4. nginx server block
5. nginx reload

The local ops directory contains the server-side helper:

`C:\Users\cn_pe\Documents\mindevo-ops\server-init-staging.sh`

Run it as `root` in Aliyun Workbench after reviewing it.

## Daily Workflow After Setup

### Small change

1. edit files locally
2. run local preview
3. run link check
4. commit
5. push
6. GitHub deploys automatically
7. review Actions logs
8. verify live site
9. update `CHANGELOG.md`

### Large or risky change

1. create a feature branch
2. open a pull request
3. wait for `Site Checks`
4. merge into `main`
5. let production deploy automatically

### Staging-first change

1. merge or push into `staging`
2. verify staging
3. merge staging into `main`
4. production deploy runs automatically
