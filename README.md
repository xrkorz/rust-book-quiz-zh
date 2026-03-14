# Rust 程序设计语言（中文版·含 Quiz）

这是一个基于 `mdBook` 的中文 Rust 学习站点，整合了《Rust 程序设计语言》简体中文内容与交互式 Quiz。

- 中文章节内容位于 `src/`
- 题库位于 `quizzes/`
- 构建产物输出到 `book/`
- 适合本地阅读，也适合部署为静态站点

## 项目来源

本仓库基于以下工作整理而成：

- [cognitive-engineering-lab/rust-book](https://github.com/cognitive-engineering-lab/rust-book)
- [KaiserY/trpl-zh-cn](https://github.com/KaiserY/trpl-zh-cn)

目标是提供一个适合公开部署的中文版 Rust Book + Quiz 仓库。

建议 GitHub 仓库名使用 `rust-book-quiz-zh`。

## 本地运行

安装依赖：

```bash
cargo install mdbook --locked --version 0.4.45
cargo install mdbook-quiz --locked
cargo install --locked --path packages/mdbook-trpl-listing
cargo install --locked --path packages/mdbook-trpl-note
```

启动本地预览：

```bash
mdbook serve --open
```

默认访问地址为 `http://localhost:3000`。

## 构建

生成静态站点：

```bash
mdbook build
```

构建结果在 `book/` 目录，可直接部署到任意静态托管平台。

## 部署方案

推荐方案是“本地构建，静态产物发布”：

1. 在仓库根目录执行 `mdbook build`
2. 生成 `book/` 目录
3. 将 `book/` 发布到静态托管平台

推荐部署平台：Cloudflare Pages。

```bash
wrangler login
./tools/deploy-pages.sh create-project
mdbook build
./tools/deploy-pages.sh
```

详细说明见 [`docs/cloudflare-pages.md`](docs/cloudflare-pages.md)。

如果你使用 GitHub Pages、Netlify、Vercel 或自建 Nginx，也只需要托管 `book/` 目录，不需要在服务器上安装 Rust 或 `mdBook`。

## 常用内容维护

修改章节内容：

```bash
$EDITOR src/ch03-01-variables-and-mutability.md
```

修改 Quiz：

```bash
$EDITOR quizzes/ch03-01-variables-and-mutability-sec1-variables.toml
```

在章节中插入 Quiz：

```markdown
{{#quiz ../quizzes/你的文件名.toml}}
```

## 仓库结构

```text
.
├── src/         # 中文章节内容
├── quizzes/     # Quiz 题库
├── listings/    # 代码示例
├── theme/       # 主题资源
├── packages/    # 本地 mdBook 插件
├── tools/       # 构建与部署脚本
└── book.toml    # mdBook 配置
```

## 许可与致谢

本仓库保留上游项目的版权与许可信息，详见 `LICENSE-APACHE`、`LICENSE-MIT`、`COPYRIGHT`。

如果你准备将此仓库发布到 GitHub 公开仓库，建议在首次提交前执行一次本地检查：

```bash
rg -n "/Users/|\\.wrangler|book/" .
```
