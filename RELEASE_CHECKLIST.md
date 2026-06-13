# Release Checklist

Use this checklist before every production deployment.

## 1. Scope

- [ ] The change has a clear purpose.
- [ ] The affected pages are listed.
- [ ] No unrelated files are included.
- [ ] Any copy, pricing, dates, phone numbers, and QR codes were reviewed.

## 2. Local Checks

- [ ] `git status` reviewed.
- [ ] `git diff` reviewed.
- [ ] JavaScript syntax checked if JS changed.
- [ ] `sitemap.xml` parsed if sitemap changed.
- [ ] Internal links checked with `check-site-links.ps1`.
- [ ] Core pages opened locally or from a local static server.

## 3. Commit

- [ ] Commit message clearly describes the change.
- [ ] Changes pushed to GitHub before deployment.
- [ ] `main` is in sync with `origin/main`.

## 4. Deploy

- [ ] Run deployment from `C:\Users\cn_pe\Documents\mindevo-ops`.
- [ ] Deployment script created a server backup.
- [ ] Deployment script smoke checks returned 200.

## 5. Production Verification

- [ ] https://www.mindevo.club/
- [ ] https://www.mindevo.club/products/
- [ ] https://www.mindevo.club/open-programs/
- [ ] https://www.mindevo.club/programs/spectrum-ai/
- [ ] https://www.mindevo.club/programs/survival-expedition/
- [ ] https://www.mindevo.club/contact/
- [ ] https://www.mindevo.club/privacy/
- [ ] https://www.mindevo.club/robots.txt
- [ ] https://www.mindevo.club/sitemap.xml
- [ ] https://www.mindevo.club/assets/js/tracking-config.js

## 6. Post-Release

- [ ] Add a `CHANGELOG.md` entry.
- [ ] Record the server backup file path.
- [ ] Check Baidu Tongji realtime traffic.
- [ ] Keep the previous release backup until the next stable release.
