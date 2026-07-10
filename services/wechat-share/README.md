# WeChat Share Signature Service

This service generates WeChat JS-SDK signatures for pages on `www.mindevo.club`.

It is intentionally dependency-free and runs on Python 3 so the ECS host does not need a Node or package-manager runtime.

## Runtime

- service file: `wechat_signature_service.py`
- default bind: `127.0.0.1:8710`
- health path: `/health`
- signing path: `/sign?url=<encoded current page url>`

Nginx exposes this as:

- `/api/wechat-js-signature/health`
- `/api/wechat-js-signature/sign?url=...`

## Required Environment

Keep secrets out of git. The production values belong in `/etc/mindevo/wechat-share.env` on the server or in GitHub Actions secrets.

```text
WECHAT_APP_ID=...
WECHAT_APP_SECRET=...
WECHAT_ALLOWED_HOSTS=www.mindevo.club,mindevo.club
WECHAT_SHARE_PORT=8710
```

## Required WeChat Public Platform Setup

Configure the JS interface security domain in the WeChat Official Account backend:

```text
www.mindevo.club
```

If this is not configured, the signature endpoint can return valid signatures, but WeChat will still reject `wx.config`.
