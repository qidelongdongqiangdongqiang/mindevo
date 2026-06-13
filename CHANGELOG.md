# Changelog

All notable production website changes are recorded here.

## 2026-06-13

### Added

- Added `robots.txt`, `sitemap.xml`, and `404.html`.
- Added canonical URLs to core pages.
- Added analytics loader and tracking configuration.
- Connected Baidu Tongji site ID.
- Established the production Git baseline from the server copy.

### Operational Notes

- Production server: `deploy@121.40.130.19:/var/www/mindevo`
- Backup after analytics deployment: `/var/www/mindevo-backups/site-20260613-075203.tgz`
- Verification: core site URLs, `robots.txt`, `sitemap.xml`, and analytics config returned HTTP 200.
