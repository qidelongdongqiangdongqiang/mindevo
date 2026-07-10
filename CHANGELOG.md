# Changelog

All notable production website changes are recorded here.

## 2026-07-10

### Added

- Added WeChat JS-SDK share wiring for shareable pages.
- Added a dependency-free Python WeChat signature service under `services/wechat-share/`.
- Added one-time ECS root setup assets under `ops/wechat-share/`.
- Added CI validation with `scripts/check-wechat-share.ps1`.
- Added WeChat share automation documentation.

### Changed

- Standardized AI spectrum camp internal links to `/programs/spectrum-ai-4/` instead of `/programs/spectrum-ai-4/index.html`.

### Manual Setup Required

- Run the ECS root setup in `ops/wechat-share/`.
- Configure the WeChat Official Account JS interface security domain for `www.mindevo.club`.
- Add `WECHAT_APP_ID` and `WECHAT_APP_SECRET` GitHub Actions secrets.
- Set `WECHAT_SHARE_ENABLED=true` after the above is complete.

## 2026-06-13

### Added

- Added a privacy notice page draft at `/privacy/`.
- Added footer links to the privacy notice.
- Added the privacy page to `sitemap.xml`.

### Pending Deployment

- Privacy notice page requires production deployment after business review.

## 2026-06-13 Initial Operations Baseline

### Added

- Added `robots.txt`, `sitemap.xml`, and `404.html`.
- Added canonical URLs to core pages.
- Added analytics loader and tracking configuration.
- Connected Baidu Tongji site ID.
- Established the production Git baseline from the server copy.

### Operational Notes

- Detailed deployment and backup records are kept in the private local ops directory.
- Verification: core site URLs, `robots.txt`, `sitemap.xml`, and analytics config returned HTTP 200.
