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

Then edit:

```text
/etc/mindevo/wechat-share.env
```

Set:

```text
WECHAT_APP_ID=...
WECHAT_APP_SECRET=...
WECHAT_ALLOWED_HOSTS=www.mindevo.club,mindevo.club
WECHAT_SHARE_PORT=8710
```

Also configure the WeChat Official Account JS interface security domain:

```text
www.mindevo.club
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

When `WECHAT_SHARE_ENABLED=true`, production deployment copies the signer service, writes the server env file, restarts the service by killing the old deploy-owned process, and smoke-checks:

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
