# Changelog

All notable production website changes are recorded here.

## 2026-10-28

### Added

- 上线「心悦星球公益行」页面：`https://www.mindevo.club/cares/`。包含公益初心、现状数据、机构介绍、16 个课程主题（家长课堂 / 亲子课堂 / 孩子专场 / 隔代教养）、公益呈现形式与社区/学校/企业合作方式。
- 微信分享使用页面内自托管的 1200×1200 封面 `cares/og-cares.jpg`。OSS 上的图片会返回 `Content-Disposition: attachment`，微信端因此不显示分享缩略图，所以该图不走 OSS。

### Changed

- `sitemap.xml` 新增 `/cares/`。
- 生产与 staging 部署工作流把 `cares/` 纳入发布包和冒烟检查，`/cares/` 返回非 200 会让部署失败。

## 2026-10-20

### Security

- 整改市委网信办 2026 年第 188 号通报的 2 个信息泄露高危漏洞：服务器 web 根目录（`/var/www/mindevo`）遗留早期手动部署的 `.git` 目录和 `README.md`，可被外网直接访问。当日已手动删除并验证 `https://121.40.130.19/.git/config`、`https://121.40.130.19/README.md` 等路径均返回 404。
- Production/staging deploy workflows now remove non-public files from the web root after every deploy (`.git`, `.github`, `docs`, `scripts`, `*.md`, `*.ps1`, `*.lock`, `*.env`, etc.), so VCS metadata and project docs can never be served again.
- Deploy smoke checks now include negative security cases: `/README.md`, `/CHANGELOG.md`, `/.git/config`, `/.git/HEAD`, `/.env`, `/composer.lock` must return 404/403, otherwise the deploy fails.
- Added `ops/nginx-security-hardening/` (root install script + nginx snippet) to block dotfiles and sensitive file types at the nginx layer as defense in depth; executed as root on the ECS host on 2026-10-22, verified 404 for sensitive paths on both production and staging with site functions unaffected.
- Audited the entire git history for hardcoded credentials (Aliyun AccessKey, private keys, WeChat AppSecret, tokens) in response to the `.git` exposure: none found, no rotation required. Manual deploy script (`mindevo-ops/deploy-static-site.ps1`) gained the same web-root cleanup step.

## 2026-09-06

### Added

- Added the "商业实战" product series: a new section on the products page (`products/index.html#business`) and a product card on the homepage, with a new card image (`assets/images/products/product-business.webp`, 800x500 crop of the generated group-discussion scene; synced to OSS by the deploy workflow).

### Changed

- Unified the product series order to 生存挑战 → 学科思维 → 科创心智 → 商业实战 → 生涯规划 → 家庭成长 → 高端定制 on both the homepage and the products page; the homepage product grid now lays out 3 cards on the top row and 4 on the bottom row (`grid three` + `grid four`).

### Fixed

- Fixed the sticky top navigation disappearing while scrolling: `overflow-x: hidden` on `html`/`body` made `body` a scroll container, which broke `position: sticky` on `.site-header`. Both now use `overflow-x: clip` (keeping `hidden` as the legacy fallback), so the nav shrinks to its compact size and stays pinned to the top.

### Changed

- Synced the expedition brochure (`programs/survival-expedition-5/`) with the latest content draft: reworked promise card, expanded challenge list, fee/contact styling, and a redesigned signup section with a dedicated signup QR code (`assets/images/signup-qr.png`).
- Updated the open-programs expedition blurb (30人精品小队) and reordered the products page series sections.

## 2026-07-27

### Added

- Activated WeChat JS-SDK share end-to-end: signature service now runs on production.
- Placed the WeChat domain verification file at the site root (`MP_verify_HBYoLW5XmmDmHFjn.txt`) and confirmed JS interface security domain for `www.mindevo.club`.
- Added WeChat Official Account IP whitelist entry `121.40.130.19`.

### Changed

- Root setup script (`ops/wechat-share/install-wechat-share-root.sh`) now installs a narrow sudoers rule granting `deploy` passwordless `systemctl restart mindevo-wechat-share.service` only.
- Production deploy workflow restarts the signer via `sudo -n systemctl restart` instead of `pkill`, so the service starts cleanly on first activation (the `deploy` user has no general sudo).
- Updated `docs/wechat-share-automation.md` to reflect the new restart mechanism and IP whitelist requirement.
- Nginx canonical redirect: non-www (`mindevo.club`) and plain HTTP now 301-redirect to `https://www.mindevo.club`, eliminating the www/non-www WeChat share inconsistency.

### Configuration

- Set GitHub secrets `WECHAT_APP_ID`, `WECHAT_APP_SECRET`.
- Set GitHub variable `WECHAT_SHARE_ENABLED=true`.
- Ran one-time ECS root setup for the systemd service, nginx reverse proxy, and sudoers rule.

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
