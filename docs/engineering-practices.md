# Engineering Practices

This site is static, but it is still a production system. Keep the workflow simple, explicit, and reversible.

## Source of Truth

- GitHub is the source of truth for website code.
- The server is a deployment target, not an editing environment.
- OSS is a static asset delivery layer, not the source of truth.
- Operational instructions live in `C:\Users\cn_pe\Documents\mindevo-ops`.

## Branching

For small urgent fixes, committing directly to `main` is acceptable only when:

- the diff is small;
- the change has been reviewed locally;
- the deploy script is used;
- the change is recorded in `CHANGELOG.md`.

For larger changes, use a branch:

```powershell
git checkout -b feature/short-description
```

Then open a pull request before merging.

## Deployment

Deploy only after the GitHub repository contains the version being deployed.

```powershell
cd C:\Users\cn_pe\Documents\mindevo-ops
.\deploy-static-site.ps1 -SourceDir "C:\Users\cn_pe\Documents\mindevo" -RemoteWebRoot "/var/www/mindevo" -SkipOss
```

The repository also contains GitHub Actions for:

- `Site Checks` on pull requests and pushes
- automatic production deploy on `main`
- automatic staging deploy on `staging`

One-time setup details live in:

```text
docs/deployment-automation-setup.md
```

## Rollback

Every deployment must have a server backup. Record the backup path in `CHANGELOG.md`.

Rollback uses the backup stored under:

```text
/var/www/mindevo-backups
```

## Analytics

- `assets/js/analytics.js` owns event logic.
- `assets/js/tracking-config.js` owns platform IDs and enable/disable flags.
- Keep `tracking-config.js` on the main site unless a stronger cache invalidation strategy is added.

## OSS

Put large and stable assets on OSS:

- images;
- CSS;
- stable shared JavaScript;
- fonts;
- PDFs or downloads.

Keep operational and fast-changing files on the main server:

- HTML;
- `robots.txt`;
- `sitemap.xml`;
- `404.html`;
- `tracking-config.js`.

## Avoid These Mistakes

- Do not edit files directly on the server.
- Do not deploy files that are not committed to GitHub.
- Do not commit secrets, SSH keys, OSS AccessKeys, or server passwords.
- Do not overwrite production with an old local folder.
- Do not skip the release checklist for changes that affect enrollment pages.
