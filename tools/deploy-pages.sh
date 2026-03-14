#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOK_DIR="${CF_PAGES_BOOK_DIR:-$ROOT_DIR/book}"
PROJECT_NAME="${CF_PAGES_PROJECT_NAME:-rust-book-quiz-zh}"
BRANCH_NAME="${CF_PAGES_BRANCH:-main}"
LOG_PATH="${WRANGLER_LOG_PATH:-${TMPDIR:-/tmp}/rust-book-quiz-wrangler.log}"
COMMAND="${1:-deploy}"

usage() {
  cat <<EOF
用法:
  ./tools/deploy-pages.sh [deploy|create-project|whoami|help]

默认行为:
  deploy          将本地 book/ 目录发布到 Cloudflare Pages

环境变量:
  CF_PAGES_PROJECT_NAME   Pages 项目名，默认: rust-book-quiz-zh
  CF_PAGES_BOOK_DIR       要发布的目录，默认: $ROOT_DIR/book
  CF_PAGES_BRANCH         绑定的 Pages 分支名，默认: main
  WRANGLER_LOG_PATH       Wrangler 日志文件路径，默认: ${TMPDIR:-/tmp}/rust-book-quiz-wrangler.log
  CF_PAGES_NO_PROXY=1     发布时临时移除代理环境变量
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "缺少命令: $1" >&2
    exit 1
  fi
}

run_wrangler() {
  local -a env_args
  env_args=("WRANGLER_LOG=error" "WRANGLER_LOG_PATH=$LOG_PATH")

  if [[ "${CF_PAGES_NO_PROXY:-0}" == "1" ]]; then
    env_args+=(
      "-u" "HTTP_PROXY"
      "-u" "HTTPS_PROXY"
      "-u" "ALL_PROXY"
      "-u" "http_proxy"
      "-u" "https_proxy"
      "-u" "all_proxy"
    )
    env -u HTTP_PROXY -u HTTPS_PROXY -u ALL_PROXY -u http_proxy -u https_proxy -u all_proxy \
      WRANGLER_LOG=error WRANGLER_LOG_PATH="$LOG_PATH" wrangler "$@"
    return
  fi

  env WRANGLER_LOG=error WRANGLER_LOG_PATH="$LOG_PATH" wrangler "$@"
}

require_command wrangler

case "$COMMAND" in
  help|-h|--help)
    usage
    ;;
  whoami)
    run_wrangler whoami
    ;;
  create-project)
    run_wrangler pages project create "$PROJECT_NAME" \
      --production-branch "$BRANCH_NAME"
    ;;
  deploy)
    if [[ ! -f "$BOOK_DIR/index.html" ]]; then
      echo "未找到可发布产物: $BOOK_DIR/index.html" >&2
      echo "请先在仓库根目录执行 mdbook build。" >&2
      exit 1
    fi

    run_wrangler pages deploy "$BOOK_DIR" \
      --project-name "$PROJECT_NAME" \
      --branch "$BRANCH_NAME"
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
