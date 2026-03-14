# 设计权衡

本节内容围绕 Rust 中的**设计权衡**展开。要成为一名高效的 Rust 工程师，仅仅了解 Rust 的工作原理是不够的——你还需要判断 Rust 众多工具中哪些适合特定的任务。在本节中，我们将通过一系列测验来考察你对 Rust 设计权衡的理解。每道测验之后，我们都会深入解析每个问题的判断依据。

下面是一道题目的示例，题目首先描述一个软件案例研究及其可能的设计方案：

> **背景：** 你正在设计一个带有全局配置的应用程序，例如包含命令行标志的配置。
>
> **功能：** 应用程序需要在各处传递对该配置的不可变引用。
>
> **设计方案：** 以下是几种实现该功能的候选设计。
>
> ```rust,ignore
> use std::rc::Rc;
> use std::sync::Arc;
>
> struct Config {
>     flags: Flags,
>     // .. 更多字段 ..
> }
>
> // 方案 1：使用引用
> struct ConfigRef<'a>(&'a Config);
>
> // 方案 2：使用引用计数指针
> struct ConfigRef(Rc<Config>);
>
> // 方案 3：使用原子引用计数指针
> struct ConfigRef(Arc<Config>);
> ```

仅凭上述背景和关键功能，三种设计方案都是潜在候选。我们需要更多关于系统目标的信息，才能判断哪些方案最为合适。因此，我们引入一个新的需求：

> 选出满足以下需求的每个设计方案：
>
> **需求：** 配置引用必须可在多个线程之间共享。
>
> **答案：**
>
> <input type="checkbox" checked disabled> 方案 1 <br>
> <input type="checkbox" disabled> 方案 2 <br>
> <input type="checkbox" checked disabled> 方案 3 <br>

从形式上说，这意味着 `ConfigRef` 实现了 [`Send`] 和 [`Sync`]。假设 `Config: Send + Sync`，则 `&Config` 和 `Arc<Config>` 均满足该需求，但 [`Rc`] 不满足（因为非原子引用计数指针不是线程安全的）。所以方案 2 不满足需求，方案 3 满足。

我们可能会倾向于认为方案 1 也不满足需求，因为 [`thread::spawn`] 等函数要求移入线程的所有数据只能包含具有 `'static` 生命周期的引用。然而，有两个原因使方案 1 并未被排除：
1. `Config` 可以存储为全局静态变量（例如，使用 [`OnceLock`]），从而可以构造 `&'static Config` 引用。
2. 并非所有并发机制都要求 `'static` 生命周期，例如 [`thread::scope`]。

因此，按照题目所述的需求，只有非 [`Send`] 类型会被排除，我们认为方案 1 和方案 3 是正确答案。

[`thread::spawn`]: https://doc.rust-lang.org/std/thread/fn.spawn.html
[`Send`]: https://doc.rust-lang.org/std/marker/trait.Send.html
[`Sync`]: https://doc.rust-lang.org/std/marker/trait.Sync.html
[`Rc`]: https://doc.rust-lang.org/std/rc/struct.Rc.html
[`OnceLock`]: https://doc.rust-lang.org/std/sync/struct.OnceLock.html
[`thread::scope`]: https://doc.rust-lang.org/std/thread/fn.scope.html

<hr>

现在请用下面的题目来练习！每个小节包含一个聚焦于单一场景的测验。完成测验后，请务必阅读每道题之后的答案解析。
 <!-- 这些问题既具有实验性，也带有主观性——如果你对我们的答案有异议，请通过 bug 按钮 🐞 留下反馈。 -->

每道测验还附有流行 Rust crate 的链接，这些 crate 为测验提供了灵感。

## 引用（References）

*灵感来源：* [Bevy assets], [Petgraph node indices], [Cargo units]

{{#quiz ../quizzes/ch17-05-design-challenge-references.toml}}


[Bevy assets]: https://docs.rs/bevy/0.11.2/bevy/asset/struct.Assets.html
[Petgraph node indices]: https://docs.rs/petgraph/0.6.4/petgraph/graph/struct.NodeIndex.html
[Cargo units]: https://docs.rs/cargo/0.73.1/cargo/core/compiler/struct.Unit.html

## Trait 树（Trait Trees）

*灵感来源：* [Yew components], [Druid widgets]

{{#quiz ../quizzes/ch17-05-design-challenge-trait-trees.toml}}

[Yew components]: https://docs.rs/yew/0.20.0/yew/html/trait.Component.html
[Druid widgets]: https://docs.rs/druid/0.8.3/druid/trait.Widget.html

## 分发（Dispatch）

*灵感来源：* [Bevy systems], [Diesel queries], [Axum handlers]

{{#quiz ../quizzes/ch17-05-design-challenge-dispatch.toml}}

[Bevy systems]: https://docs.rs/bevy_ecs/0.11.2/bevy_ecs/system/trait.IntoSystem.html
[Diesel queries]: https://docs.diesel.rs/2.1.x/diesel/query_dsl/trait.BelongingToDsl.html
[Axum handlers]: https://docs.rs/axum/0.6.20/axum/handler/trait.Handler.html

## 中间层（Intermediates）

*灵感来源：* [Serde] 和 [miniserde]

{{#quiz ../quizzes/ch17-05-design-challenge-intermediates.toml}}

[Serde]: https://docs.rs/serde/1.0.188/serde/trait.Serialize.html
[miniserde]: https://docs.rs/miniserde/0.1.34/miniserde/trait.Serialize.html
