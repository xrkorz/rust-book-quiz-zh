# 实验介绍

欢迎参与 Rust 书籍实验，感谢你的参与！本书是 [*The Rust Programming Language*](http://doc.rust-lang.org/book/) 的实验性分支，引入了多种机制，使学习 Rust 的过程更具互动性。以下是对各项机制的简要介绍：

## 1. 测验（Quizzes）

核心机制是**测验**：每个页面都有几道关于页面内容的测验。在本实验中，测验有两条规则：

1. **遇到测验时立即作答。**
2. **不要跳过测验。**

（我们不会强制执行这些规则，但请自觉遵守！）

每道测验的形式如下所示。点击"Start"试试看。

{{#quiz ../quizzes/example-quiz.toml}}

如果某道题答错了，你可以选择重新作答，或查看正确答案。我们建议你反复重试，直到答对 100% 为止——重试前可以随时回顾相关内容。请注意，一旦查看了正确答案，便无法再重试该测验。

如果你发现测验或书中其他部分有问题，可以在我们的 Github 仓库提交 issue：<https://github.com/cognitive-engineering-lab/rust-book>

## 2. 高亮（Highlighting）

另一个机制是**高亮**：你可以选中任意一段文字，对其进行高亮或留下评论。选中文字后，点击 ✏️ 按钮，即可输入可选的评论。

👉 试试高亮这段文字！ 👈

你可以用高亮为自己保存重要信息，也可以用高亮向我们提供反馈——例如，如果你觉得某段内容令人困惑，可以通过高亮告知我们。

> **注意：** 如果我们修改了你高亮的内容，你的高亮将会消失。此外，高亮内容以 cookie 形式存储。若你禁用了 cookie 或更换了浏览器，则将看不到之前的高亮。

## 3. ……以及更多！

书中内容可能会在你参与实验的过程中有所更新。我们会在此页面记录新增功能的更新日志：

* 2024 年 9 月 26 日
  * Chris Krycho 撰写的 async Rust 章节已添加，并附有新的测验题目。
* 2023 年 2 月 16 日
  * 一个关于所有权的新章节已替换原第 4 章。
* 2023 年 1 月 18 日
  * 书中其余章节已添加相应题目。
* 2022 年 12 月 15 日
  * 书中各处新增了名为"所有权清单"的章节，包含具有挑战性的所有权相关题目。
* 2022 年 11 月 7 日
  * 重试时将只显示答错的题目。
  * 大多数单选题的选项将随机排列。
  * 部分题目现在会要求你说明答题理由。
  * 根据你的反馈，许多题目已进行更新，欢迎继续提供反馈！

_有兴趣参与其他关于 Rust 学习的实验？请在此报名：_ <https://forms.gle/U3jEUkb2fGXykp1DA>

## 4. 学术发表（Publications）

迄今为止，本实验已催生两篇开放获取的学术论文。如果你有兴趣了解本书背后的学术研究，欢迎查阅：

* [Profiling Programming Language Learning](https://dl.acm.org/doi/10.1145/3649812) <br />
  Will Crichton 和 Shriram Krishnamurthi. OOPSLA 2024.（杰出论文奖）

* [A Grounded Conceptual Model for Ownership Types in Rust](https://dl.acm.org/doi/10.1145/3622841) <br />
  Will Crichton、Gavin Gray 和 Shriram Krishnamurthi. OOPSLA 2023.（SIGPLAN 研究亮点及 ACM 通讯研究亮点）

## 5. 致谢（Acknowledgments）

本研究部分由 DARPA 根据协议编号 HR00112420354 资助，部分由 NSF 根据奖项编号 CCF-2227863 资助，部分由亚马逊云科技资助。本材料中表达的任何意见、发现、结论或建议均属于作者本人，不代表资助方的观点。Carol Nichols 和 Rust 基金会协助推广了本实验。TRPL 的诞生凝聚了众多前人在我们开展本实验之前的辛勤付出。
