# 心悦星球官网微信分享问题排查记录

> 记录人：ZCode
> 时间：2026-07-28
> 背景：接手 Codex 留下的官网后，尝试把微信分享（JS-SDK）完全自动化并调通，最终未能在所有场景下成功。

## 一、我们到底在解决什么问题

微信里分享网页链接有两种表现：

1. **普通链接预览**（粘贴 URL 到聊天）：微信服务器抓取页面的 `og:title` / `og:description` / `og:image` 生成卡片。
2. **JS-SDK 自定义分享**（在网页内点右上角「···」→ 转发）：前端调用 `wx.config()` + `wx.onMenuShareAppMessage()`，由开发者指定标题/描述/图/链接。

我们建设的是第 2 种，因为第 1 种不可控、且微信内经常不抓取或抓不全。

## 二、已经建成的部分（都是正常的）

| 组件 | 状态 | 验证方式 |
|---|---|---|
| 后端签名服务 | ✅ 正常 | `https://www.mindevo.club/api/wechat-js-signature/health` 返回 `{"ok":true,"configured":true}` |
| 签名生成 | ✅ 正常 | `/api/wechat-js-signature/sign?url=...` 返回有效 signature |
| GitHub Secrets | ✅ 已设 | `WECHAT_APP_ID` / `WECHAT_APP_SECRET` |
| GitHub Variable | ✅ 已设 | `WECHAT_SHARE_ENABLED=true` |
| JS 安全域名 | ✅ 已设 | `www.mindevo.club` 和 `mindevo.club` |
| IP 白名单 | ✅ 已设 | `121.40.130.19` |
| 网页授权域名 | ✅ 已设 | `www.mindevo.club` 和 `mindevo.club` |
| nginx 反代 | ✅ 正常 | `/api/wechat-js-signature/*` → `127.0.0.1:8710` |
| systemd 服务 | ✅ 正常 | `mindevo-wechat-share.service` 由 deploy 用户 `systemctl restart` |
| 前端加载 | ✅ 正常 | 所有可分享页都加载 `jweixin-1.6.0.js` + `wechat-share.js` |
| HTML 元数据 | ✅ 正常 | 所有页面都有完整的 `og:*` 标签，且已去 BOM |
| 图片格式 | ✅ 已换 JPG | `og:image` 全部指向 `.jpg`，大小 800×800 |
| 域名重定向 | ✅ 正常 | 非 www 已 301 到 `https://www.mindevo.club/...` |
| 部署自动化 | ✅ 正常 | push `main` → GitHub Actions → 服务器 + OSS 自动部署 |

## 三、实际观察到的现象

### 3.1 手机端（iOS/Android 微信）

- 在网页内点右上角「···」→「转发给朋友」，分享出去是**纯网址**，没有卡片样式。
- 早期偶尔出现过光谱营页面能出卡片（带图），但极不稳定，后来就一直是纯网址。
- 新建了一个**只有 og 标签、不带 JS-SDK** 的测试页，分享出去也是纯网址。

### 3.2 电脑端微信

- 在会话里打开链接，点转发，能出卡片样式（标题/描述）。
- 但**右边小图缺失**。

### 3.3 关键对比实验

用户发现：
> 从分享卡片点进去 → 再分享，能保留卡片样式；复制该页 URL 粘贴到聊天 → 再从聊天打开 → 分享，又变回纯网址。

这提示**打开入口/URL 参数**可能影响微信的分享行为，但尝试用规范 URL 签名后，手机端情况反而更差，于是又回退到当前地址栏 URL 签名。

## 四、尝试过但没有奏效的方案

| 方案 | 结果 |
|---|---|
| 新版分享 API `updateAppMessageShareData` / `updateTimelineShareData` | 桌面端报 `function not implement`，手机端也不稳定 |
| 降级到老版 API `onMenuShareAppMessage` / `onMenuShareTimeline` | 手机端仍是纯网址 |
| 去掉 HTML BOM | 无变化 |
| `og:image` 从 WebP 换成 JPG | 无变化 |
| 签名 URL 用规范 URL（去微信参数） | 手机端反而彻底不行，已回退 |
| 改 OSS `Content-Disposition` 为 `inline` | 用了 ossutil v2 metadata、v1 --meta、oss2 SDK copy、v1 set-meta 四种方法，全部失败，响应头仍为 `attachment` |

## 五、目前最可能的根因判断

1. **手机端纯网址**：不是代码问题。微信对该域名/账号的链接预览或 JS-SDK 自定义分享没有建立信任，可能原因包括：
   - 域名太新 / `.club` 后缀信任度低；
   - 公众号虽然已认证，但缺少某个隐藏能力开关；
   - 该域名被微信爬虫判定为低优先级，未收录；
   - 账号或域名历史上无违规，但也不在"优质域名"白名单里。

2. **电脑端有卡片没图**：`Content-Disposition: attachment` 导致微信不渲染缩略图。但自动化脚本无法修改这个响应头，需人工在 OSS 控制台处理。

## 六、如果以后还要再调，建议的排查顺序

1. **先看签名服务健康**：`https://www.mindevo.club/api/wechat-js-signature/health`
2. **再用 debug 模式**：临时把 `wechat-share.js` 的 `debug` 设为 `true`，观察 `wx.config` 弹窗是 `config:ok` 还是 `config:fail`，以及具体错误码。
3. **确认公众号后台**：
   - 账号类型必须是"微信认证服务号"；
   - JS 接口安全域名包含 `www.mindevo.club` 和 `mindevo.club`；
   - 网页授权域名包含上述两个；
   - IP 白名单包含 `121.40.130.19`。
4. **检查 OSS 图片头**：`curl -I https://mindevo-static.oss-cn-hangzhou.aliyuncs.com/assets/images/og-image.jpg`，确认 `Content-Disposition` 是否为 `inline`。
5. **尝试纯 og 标签页面**：新建一个无 JS-SDK 的测试页，看微信是否会自动生成链接预览。
6. **联系微信客服/技术支持**：如果以上都正常但仍不出卡片，基本确定是微信侧限制。

## 七、关于"每个页面单独写分享样式"的说明

这也是一种可行思路，本质上有两种做法：

### A. 每页内联 `<script>` 直接调 `wx.config`
把现在 `wechat-share.js` 里的逻辑复制到每个页面的 `</body>` 前，写死该页的标题/图/链接。

**优点**：不需要统一 JS 文件，逻辑直观。
**缺点**：
- 代码重复，维护麻烦；
- 签名 URL、安全域名、IP 白名单等约束不变，如果当前统一方案因为微信侧限制失败，分散写也会失败。

### B. 不用 JS-SDK，只依赖 `og` 标签
删掉 `jweixin` 和 `wechat-share.js`，只保留 `og:*` 标签。

**优点**：最简单，没有微信配置负担。
**缺点**：
- 分享卡片完全由微信爬虫决定，不可控；
- 我们已测试过纯 og 标签页面，微信没有生成卡片。

**结论**：当前核心问题不是"统一设置 vs 每页设置"的技术选型问题，而是**微信对这个域名/账号没有稳定生成分享卡片**。换成每页写死，大概率得到同样结果。

## 八、遗留动作

- [ ] 桌面端小图：需要手动在阿里云 OSS 控制台把 `assets/images/og-*.jpg` 的 `Content-Disposition` 从 `attachment` 改为 `inline`。
- [ ] 手机端：建议运营一段时间后观察，或联系微信技术支持排查账号/域名信任问题。
