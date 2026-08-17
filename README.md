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
.env.example               后端地址的样板，复制成 .env 填真实地址
make-config.sh             由 .env 生成 config.js
config.js                  后端地址，不进仓库（.env / GitHub secret 生成）
.github/workflows/deploy.yml
```

**`.nojekyll` 不能删。** GitHub Pages 默认跑 Jekyll，而 Jekyll 会忽略所有下划线开头的
目录——`_ds/` 整个不会被发布，页面打得开但完全没有样式。这个坑不报错，只是变丑。

## 后端地址怎么配

**真实地址不写在代码里。** 仓库是公开的，地址只存在两个地方：本地的 `.env`，和
仓库 Settings → Secrets and variables → Actions 里的 secret `API_BASE`。两边都由同一段
逻辑落成一个 `config.js`（`window.APP_CONFIG = { apiBase: "..." }`），这个文件在
`.gitignore` 里，永远不进 git。

页面按优先级从四个地方取：

| 优先级 | 来源 | 用途 |
|---|---|---|
| 1 | `?api=https://...` | 临时指向别的后端，同时记进 localStorage |
| 2 | localStorage | 上次用 `?api=` 指定过的，之后直接打开还是它 |
| 3 | `config.js` | 部署时由 secret `API_BASE` 生成 |
| 4 | 空 | 都没有就 fetch 失败，页面退化成示例数据 |

```
https://lilmuh.github.io/bnb-redpacket-frontend/?api=https://你的后端
```

> 这只是让地址不进 git 历史。站点本身是公开的，`config.js` 会随页面发给每个访客——
> 想让访客也看不到地址，就别配 `API_BASE` secret，只把带 `?api=` 的链接发给该看的人。

**默认值必须是 https。** 页面部署在 `https://lilmuh.github.io` 上，浏览器不允许 HTTPS
页面去 fetch 一个 http 地址。填成 `http://127.0.0.1:8770` 不会报错，只会被静默拦掉，
页面退化成内置的示例数据——看着一切正常，数字全是假的。

**怎么分辨在看的是不是真数据：** 右上角「来源」那行会写实际的后端地址；连不上时写
「示例数据（后端未连通）」。示例数据固定是 348 条记录 / 领取成功 223。

## 本地开发

页面本身是 http 来源，不受混合内容限制，直接指本机后端就行：

```bash
cp .env.example .env    # 填上后端地址
./make-config.sh        # 生成 config.js
python -m http.server 8780
# 打开 http://127.0.0.1:8780/?api=http://127.0.0.1:8770
```

## 部署

1. 仓库 Settings → Pages → Source 选 **GitHub Actions**
2. Settings → Secrets and variables → Actions → New repository secret，
   名字 `API_BASE`，值是后端的公网 https 地址
3. push 到 `main`

改后端地址不用改代码：改掉 secret，然后在 Actions 页面点 **Run workflow** 重跑一次。

后端那边还要做两件事，否则页面拿不到数据：

1. 用 Tailscale Funnel 把 `run_api.py` 暴露成一个公网 https 地址
2. 把 `https://lilmuh.github.io` 加进后端 `.env` 的 `WEB_ALLOWED_ORIGIN_REGEX`

细节见 `bnb-redpacket/worker/README.md`。

> **注意**：后端的 `PATCH /api/claim-attempts/{id}/status` 能改数据库里的领取状态，
> 目前**没有任何鉴权**。用 Funnel 公开之后，任何知道地址的人都能改。
> 上线前请先看后端 README 里关于鉴权的那节。
