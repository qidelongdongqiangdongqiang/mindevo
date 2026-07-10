# 心悦星球 MindEvo 官网

> 专注为青少年构建 AI 时代的心智优势

## 当前工作方式

- GitHub 仓库是代码唯一事实源
- 阿里云服务器是生产运行环境
- OSS 是静态资源分发层
- 本地运维入口在 `C:\Users\cn_pe\Documents\mindevo-ops`

## 自动化状态

仓库内已经包含：

- PR / Push 的站内链接检查
- `main` 分支自动部署到生产
- `staging` 分支自动部署到预发布

完整的一次性配置说明见：

```text
docs/deployment-automation-setup.md
```

## 网站结构

```
/
├── index.html                          # 首页（时代使命）
├── products/
│   └── index.html                      # 产品系列
├── open-programs/
│   └── index.html                      # 正在招生
├── contact/
│   └── index.html                      # 联系我们
├── programs/
│   ├── survival-expedition/
│   │   └── index.html                  # 生存远征营招生简章
│   └── spectrum-ai/
│       └── index.html                  # AI光谱科创心智营招生简章
└── assets/
    ├── css/site.css                    # 全局样式
    ├── js/site.js                      # 交互脚本
    └── images/                         # 图片资源
```

## 微信分享配置

所有可分享页面使用两层配置：

- Open Graph (OG) 标签负责标题、描述、图片和规范链接
- 微信 JS-SDK 负责在微信内显式注册分享卡片

微信 JS-SDK 签名由仓库内的 Python 服务提供：

```text
services/wechat-share/wechat_signature_service.py
```

自动化与一次性服务器配置说明见：

```text
docs/wechat-share-automation.md
```

## 本地预览

直接用浏览器打开 `index.html` 即可。

## 部署到 GitHub Pages

1. 将所有文件推送到 GitHub 仓库
2. 进入仓库 Settings → Pages
3. Source 选择 `Deploy from a branch`
4. Branch 选择 `main` + `/root`
5. 等待 1-2 分钟即可访问

## 技术栈

- 纯静态 HTML + CSS + JavaScript
- 响应式设计（移动端/桌面端适配）
- CSS Grid / Flexbox 布局

---

© 2026 重庆心悦星球心理健康科技有限公司
