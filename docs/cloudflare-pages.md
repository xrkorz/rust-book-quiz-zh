# Cloudflare Pages 部署说明

本项目采用“本地构建，Pages 直发静态产物”的方式部署。

- 构建目录固定为 [`book/`](../book/)
- Cloudflare 只托管静态 HTML、CSS、JS 和资源文件
- 不在 Cloudflare 上安装 `mdbook`、`mdbook-quiz` 或 Rust 工具链

## 约定

- 默认 Pages 项目名：`rust-book-quiz-zh`
- 默认发布目录：`book/`
- 默认生产分支名：`main`
- 默认访问域名：Cloudflare 自动分配的 `*.pages.dev`

如需覆盖这些默认值，可在执行时设置环境变量：

```bash
CF_PAGES_PROJECT_NAME=your-project-name \
CF_PAGES_BRANCH=main \
./tools/deploy-pages.sh
```

## 首次部署

### 1. 确认本地静态产物存在

```bash
cd <repo-root>
mdbook build
```

执行后应存在 [`book/index.html`](../book/index.html)。

### 2. 登录 Cloudflare

```bash
wrangler login
```

如需确认当前登录状态：

```bash
./tools/deploy-pages.sh whoami
```

### 3. 创建 Pages 项目

```bash
./tools/deploy-pages.sh create-project
```

脚本会自动以 `main` 作为 Pages 的 production branch 创建项目。

如果你想使用其他项目名：

```bash
CF_PAGES_PROJECT_NAME=my-rust-book \
./tools/deploy-pages.sh create-project
```

### 4. 发布本地 `book/`

```bash
./tools/deploy-pages.sh
```

发布成功后，Cloudflare 会返回本次部署 URL 和项目的 `pages.dev` 域名。

## 日常更新发布

内容更新后，本地重新构建，再次执行发布即可：

```bash
cd <repo-root>
mdbook build
./tools/deploy-pages.sh
```

这会把最新 `book/` 内容上传到同一个 Pages 项目。

## 常用环境变量

```bash
CF_PAGES_PROJECT_NAME=rust-book-quiz-zh
CF_PAGES_BOOK_DIR=./book
CF_PAGES_BRANCH=main
```

## 代理与日志兼容

本机 `wrangler` 默认可能尝试把日志写到用户目录。仓库自带的发布脚本会把日志路径固定到临时目录，避免因为日志写入失败而中断。

如果本机代理配置导致 `wrangler` 连接异常，可在发布时临时移除代理环境变量：

```bash
CF_PAGES_NO_PROXY=1 ./tools/deploy-pages.sh whoami
CF_PAGES_NO_PROXY=1 ./tools/deploy-pages.sh
```

## 验证清单

发布后至少检查以下内容：

- 首页可打开
- 目录页可用
- 至少 3 个章节页面无 404
- 至少 1 个 Quiz 可提交
- 刷新后答题状态仍保留在浏览器 `localStorage`
- 浏览器控制台无关键静态资源加载错误

## 回滚

Cloudflare Pages 的回滚建议直接在 Cloudflare 控制台中选择上一条成功部署并恢复。

如果只是重新发布到旧版本内容，也可以在本地切回目标版本的 `book/` 产物后再次执行：

```bash
./tools/deploy-pages.sh
```
