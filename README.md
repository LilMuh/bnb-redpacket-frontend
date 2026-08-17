# bnb-redpacket-frontend

「红包领取情况」看板页面。数据来自 [`LilMuh/bnb-redpacket`](https://github.com/LilMuh/bnb-redpacket)
里的 `run_api.py`。

纯静态：一个 `index.html` + 一份 dc-runtime + 一份设计系统的 CSS，没有构建步骤，
push 到 `main` 就自动部署到 GitHub Pages。

```
index.html                 页面本体（模板 + 逻辑都在这一个文件里）
support.js                 dc-runtime，渲染 <x-dc> / <sc-for> / <sc-if>
_ds/classical-…/           设计系统的 tokens 和组件样式
.nojekyll                  必须有，见下
.github/workflows/deploy.yml
```

**`.nojekyll` 不能删。** GitHub Pages 默认跑 Jekyll，而 Jekyll 会忽略所有下划线开头的
目录——`_ds/` 整个不会被发布，页面打得开但完全没有样式。这个坑不报错，只是变丑。

## 后端地址怎么配

静态站部署后没法重新构建，所以后端地址按优先级从三个地方取：

| 优先级 | 来源 | 用途 |
|---|---|---|
| 1 | `?api=https://...` | 临时指向别的后端，同时记进 localStorage |
| 2 | localStorage | 上次用 `?api=` 指定过的，之后直接打开还是它 |
| 3 | `index.html` 里的 `DEFAULT_API_BASE` | 默认值 |

```
https://lilmuh.github.io/bnb-redpacket-frontend/?api=https://你的后端
```

**默认值必须是 https。** 页面部署在 `https://lilmuh.github.io` 上，浏览器不允许 HTTPS
页面去 fetch 一个 http 地址。填成 `http://127.0.0.1:8770` 不会报错，只会被静默拦掉，
页面退化成内置的示例数据——看着一切正常，数字全是假的。

**怎么分辨在看的是不是真数据：** 右上角「来源」那行会写实际的后端地址；连不上时写
「示例数据（后端未连通）」。示例数据固定是 348 条记录 / 领取成功 223。

## 本地开发

页面本身是 http 来源，不受混合内容限制，直接指本机后端就行：

```bash
python -m http.server 8780
# 打开 http://127.0.0.1:8780/?api=http://127.0.0.1:8770
```

## 部署

仓库 Settings → Pages → Source 选 **GitHub Actions**，然后 push 到 `main`。

后端那边还要做两件事，否则页面拿不到数据：

1. 用 Tailscale Funnel 把 `run_api.py` 暴露成一个公网 https 地址
2. 把 `https://lilmuh.github.io` 加进后端 `.env` 的 `WEB_ALLOWED_ORIGIN_REGEX`

细节见 `bnb-redpacket/worker/README.md`。

> **注意**：后端的 `PATCH /api/claim-attempts/{id}/status` 能改数据库里的领取状态，
> 目前**没有任何鉴权**。用 Funnel 公开之后，任何知道地址的人都能改。
> 上线前请先看后端 README 里关于鉴权的那节。
