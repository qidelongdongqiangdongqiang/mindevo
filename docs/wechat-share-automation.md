# WeChat Share Automation

This site uses WeChat JS-SDK for deterministic sharing inside WeChat.

## Why This Exists

Open Graph tags help normal link previews, but they do not reliably control WeChat in-app sharing. WeChat needs `wx.config` with a signature generated for the exact current page URL.

The implementation has three parts:

1. page metadata: canonical URL and `og:*` tags
2. frontend loader: `/assets/js/wechat-share.js`
3. backend signer: `/api/wechat-js-signature/sign`

## One-Time Manual Setup

The server `deploy` user cannot edit nginx or systemd. Run the root setup once from the ECS host:

```bash
cd /path/to/repo/ops/wechat-share
bash install-wechat-share-root.sh
```

The script creates a placeholder `/etc/mindevo/wechat-share.env`. You do not need to edit it manually — the production deploy writes the real `WECHAT_APP_ID` / `WECHAT_APP_SECRET` into it from the GitHub secrets on each release. The placeholder only needs to exist so directory ownership is correct.

Also configure the WeChat Official Account JS interface security domain:

```text
www.mindevo.club
```

Also add the server's outbound IP to the Official Account IP whitelist, otherwise the `access_token` call is rejected with `errcode 40164`:

```text
121.40.130.19
```

## GitHub Actions Settings

Set repository variable:

```text
WECHAT_SHARE_ENABLED=true
```

Set repository secrets:

```text
WECHAT_APP_ID
WECHAT_APP_SECRET
```

When `WECHAT_SHARE_ENABLED=true`, production deployment copies the signer service, writes the server env file (from the GitHub secrets), restarts the service via `sudo systemctl restart mindevo-wechat-share.service` (the root setup grants `deploy` a narrow sudoers rule for this one command), and smoke-checks:

```text
https://www.mindevo.club/api/wechat-js-signature/health
```

## Page Requirements

Every shareable page needs:

- canonical URL
- `og:title`
- `og:description`
- absolute `og:image`
- canonical `og:url`
- WeChat loader scripts before `</body>`

The CI check enforces these rules:

```powershell
./scripts/check-wechat-share.ps1 -SourceDir .
```

## URL Rule

Do not link to enrollment pages with `index.html`.

Use:

```text
/programs/spectrum-ai-4/
```

not:

```text
/programs/spectrum-ai-4/index.html
```
