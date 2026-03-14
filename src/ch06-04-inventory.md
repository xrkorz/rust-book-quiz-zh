## 所有权清单 #1

所有权清单是一系列测验，用于检验你在真实场景中对所有权的理解。这些场景灵感来源于关于 Rust 的常见 StackOverflow 问题。你可以用这些问题来测试你目前对所有权的掌握程度。

### 一项新技术：浏览器内 IDE

这些问题涉及使用你之前未见过的函数的 Rust 程序。因此，我们将使用一项在浏览器中支持 IDE 功能的实验性技术。该 IDE 让你可以获取关于不熟悉函数和类型的信息。例如，在下面的程序中尝试以下操作：

* 将鼠标悬停在 `replace` 上，查看其类型和说明。
* 将鼠标悬停在 `s2` 上，查看其推断类型。

---------


<pre>
<code class="ide">
/// Turns a string into a far more exciting string
fn make_exciting(s: &str) -> String {
  let s2 = s.replace(".", "!");
  let s3 = s2.replace("?", "‽");
  s3
}
</code>
</pre>

---------

关于这项实验性技术，有几点重要说明：

**平台兼容性：** 浏览器内 IDE 不支持触摸屏。浏览器内 IDE 仅经过 Google Chrome 109 和 Firefox 107 的测试，在较旧版本的 Safari 中可能无法正常工作。

**内存占用：** 浏览器内 IDE 使用 [WebAssembly](https://rustwasm.github.io/book/) 构建的 [rust-analyzer](https://github.com/rust-lang/rust-analyzer)，可能占用相当多的内存。每个 IDE 实例大约需要约 300 MB。（注意：我们也收到了一些超过 10GB 内存占用的报告。）

**滚动问题：** 如果光标与编辑器相交，浏览器内 IDE 会"捕获"你的光标。如果滚动页面遇到困难，请尝试将光标移动到最右侧的滚动条上。

**加载时间：** IDE 初始化新程序可能需要最多 15 秒。当你与编辑器中的代码交互时，它会显示"Loading..."。

### 测验

{{#quiz ../quizzes/ch06-04-inventory.toml}}
