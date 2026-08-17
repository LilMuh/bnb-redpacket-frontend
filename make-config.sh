#!/usr/bin/env sh
# 由 .env 生成 config.js（两个都在 .gitignore 里）。
# 部署时不跑这个脚本——workflow 直接从 GitHub secret 写同样的文件。
set -e
cd "$(dirname "$0")"

[ -f .env ] || { echo "没有 .env，先 cp .env.example .env 并填上地址" >&2; exit 1; }
# shellcheck disable=SC1091
. ./.env

[ -n "$API_BASE" ] || { echo ".env 里的 API_BASE 是空的" >&2; exit 1; }

printf 'window.APP_CONFIG = { apiBase: "%s" };\n' "$API_BASE" > config.js
echo "已写 config.js -> $API_BASE"
