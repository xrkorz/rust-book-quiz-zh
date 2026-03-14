## Slice 类型

*Slice* 让你可以引用[集合](ch08-00-common-collections.md)中一段连续的元素序列，而不是整个集合。Slice 是一种引用，因此它是非所有权指针。

为了说明 slice 的用处，让我们来解决一个小编程问题：编写一个函数，接受一个由空格分隔单词的字符串，并返回在该字符串中找到的第一个单词。如果函数在字符串中找不到空格，则整个字符串就是一个单词，应返回整个字符串。在没有 slice 的情况下，我们可能会这样写函数签名：

```rust,ignore
fn first_word(s: &String) -> ?
```

`first_word` 函数以 `&String` 作为参数。我们不需要字符串的所有权，所以这没问题。但我们应该返回什么？我们没有真正的方式来描述字符串的*一部分*。不过，我们可以返回单词末尾的索引，用空格来标示。让我们试试这种方法，如代码清单 4-7 所示。

<span class="filename">文件名：src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch04-understanding-ownership/listing-04-07/src/main.rs:here}}
```

<span class="caption">代码清单 4-7：返回 `String` 参数中字节索引值的 `first_word` 函数</span>

因为我们需要逐元素遍历 `String` 并检查某个值是否为空格，所以我们使用 `as_bytes` 方法将 `String` 转换为字节数组：

```rust,ignore
{{#rustdoc_include ../listings/ch04-understanding-ownership/listing-04-07/src/main.rs:as_bytes}}
```

接下来，我们使用 `iter` 方法在字节数组上创建迭代器：

```rust,ignore
{{#rustdoc_include ../listings/ch04-understanding-ownership/listing-04-07/src/main.rs:iter}}
```

我们将在[第 13 章][ch13]<!-- ignore -->中详细讨论迭代器。现在只需知道，`iter` 是一个返回集合中每个元素的方法，而 `enumerate` 包装了 `iter` 的结果，将每个元素作为元组的一部分返回。`enumerate` 返回的元组的第一个元素是索引，第二个元素是对该元素的引用。这比自己计算索引要方便一些。

因为 `enumerate` 方法返回一个元组，我们可以使用模式来解构这个元组。我们将在[第 6 章][ch6]<!-- ignore -->中更详细地讨论模式。在 `for` 循环中，我们指定了一个模式，其中 `i` 对应元组中的索引，`&item` 对应元组中的单个字节。因为我们从 `.iter().enumerate()` 获得的是元素的引用，所以在模式中使用 `&`。

在 `for` 循环内部，我们使用字节字面量语法搜索表示空格的字节。如果找到空格，就返回该位置。否则，使用 `s.len()` 返回字符串的长度：

```rust,ignore
{{#rustdoc_include ../listings/ch04-understanding-ownership/listing-04-07/src/main.rs:inside_for}}
```

现在我们有办法找出字符串中第一个单词末尾的索引了，但这里有一个问题。我们返回的是一个独立的 `usize`，但它只在 `&String` 的上下文中才有意义。换句话说，因为它是一个独立于 `String` 的值，无法保证它在将来仍然有效。请考虑代码清单 4-8，它使用了代码清单 4-7 中的 `first_word` 函数。

<span class="filename">文件名：src/main.rs</span>

```aquascope,interpreter+permissions,boundaries,stepper,horizontal
fn first_word(s: &String) -> usize {
    let bytes = s.as_bytes();

    for (i, &item) in bytes.iter().enumerate() {
        if item == b' ' {
            return i;
        }
    }

    s.len()
}

fn main() {
    let mut s = String::from("hello world");`(focus)`
    let word = first_word(&s);`[]`
    s.clear();`[]``{}`
}
```

<span class="caption">代码清单 4-8：存储调用 `first_word` 函数的结果，然后修改 `String` 的内容</span>

这个程序编译时没有任何错误，因为调用 `first_word` 后 `s` 仍然保留了写权限。由于 `word` 与 `s` 的状态完全没有关联，`word` 仍然包含值 `5`。我们可以尝试用变量 `s` 和值 `5` 来提取第一个单词，但这会是一个 bug，因为自从我们将 `5` 保存到 `word` 后，`s` 的内容已经改变了。

必须担心 `word` 中的索引与 `s` 中的数据不同步，这既繁琐又容易出错！如果再写一个 `second_word` 函数，管理这些索引会更加脆弱。它的签名必须是这样的：

```rust,ignore
fn second_word(s: &String) -> (usize, usize) {
```

现在我们需要跟踪起始*和*结束索引，并且有更多从特定状态的数据中计算出来但与该状态完全无关的值。我们有三个不相关的变量四处游荡，需要保持同步。

幸运的是，Rust 有一个解决方案：字符串 slice。

### 字符串 Slice

*字符串 slice* 是对 `String` 一部分内容的引用，看起来像这样：

```aquascope,interpreter
#fn main() {
let s = String::from("hello world");

let hello: &str = &s[0..5];
let world: &str = &s[6..11];
let s2: &String = &s; `[]`
#}
```

`hello` 不是对整个 `String` 的引用（像 `s2` 那样），而是对 `String` 一部分的引用，由额外的 `[0..5]` 指定。我们使用在方括号内指定范围的方式来创建 slice，格式为 `[starting_index..ending_index]`，其中 `starting_index` 是 slice 中第一个位置，`ending_index` 比 slice 中最后一个位置多一。

Slice 是特殊的引用，因为它们是"胖"指针，即带有元数据的指针。这里的元数据是 slice 的长度。通过将可视化切换为查看 Rust 数据结构的内部，我们可以看到这些元数据：

```aquascope,interpreter,concreteTypes,hideCode
fn main() {
    let s = String::from("hello world");

    let hello: &str = &s[0..5];
    let world: &str = &s[6..11];
    let s2: &String = &s; // not a slice, for comparison
    `[]`
}
```

注意，变量 `hello` 和 `world` 都有 `ptr` 和 `len` 字段，它们共同定义了堆上字符串中被下划线标注的区域。你也可以在这里看到 `String` 实际的样子：字符串是一个字节向量（`Vec<u8>`），包含长度 `len` 和一个具有指针 `ptr` 和容量 `cap` 的缓冲区 `buf`。

因为 slice 是引用，它们也会改变被引用数据的权限。例如，下面可以看到，当 `hello` 作为 `s` 的 slice 被创建时，`s` 失去了写入和所有权限：

```aquascope,permissions,stepper,boundaries
fn main() {
    let mut s = String::from("hello");
    let hello: &str = &s[0..5];
    println!("{hello}");
    s.push_str(" world");
}
```

#### 范围语法

使用 Rust 的 `..` 范围语法，如果想从索引零开始，可以省略两个点之前的值。换句话说，这两者是等价的：

```rust
let s = String::from("hello");

let slice = &s[0..2];
let slice = &s[..2];
```

同样，如果 slice 包含 `String` 的最后一个字节，可以省略末尾的数字。这意味着这两者是等价的：

```rust
let s = String::from("hello");

let len = s.len();

let slice = &s[3..len];
let slice = &s[3..];
```

你也可以省略两个值来获取整个字符串的 slice。所以这两者是等价的：

```rust
let s = String::from("hello");

let len = s.len();

let slice = &s[0..len];
let slice = &s[..];
```

> 注意：字符串 slice 的范围索引必须位于有效的 UTF-8 字符边界处。如果尝试在多字节字符的中间创建字符串 slice，程序将以错误退出。本节在介绍字符串 slice 时，假设只使用 ASCII 字符；关于 UTF-8 处理的更深入讨论，请参阅第 8 章的["用字符串存储 UTF-8 编码的文本"][strings]<!-- ignore -->一节。

#### 用字符串 slice 重写 `first_word`

了解了以上所有信息后，让我们重写 `first_word` 以返回一个 slice。表示"字符串 slice"的类型写作 `&str`：

<span class="filename">文件名：src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch04-understanding-ownership/no-listing-18-first-word-slice/src/main.rs:here}}
```

我们用与代码清单 4-7 相同的方式获取单词末尾的索引，即查找第一个空格的出现位置。当找到空格时，我们返回一个字符串 slice，使用字符串的开头和空格的索引作为起始和结束索引。

现在调用 `first_word` 时，我们得到的是一个与底层数据绑定的单一值。该值由指向 slice 起始点的引用和 slice 中元素的数量组成。

返回 slice 对 `second_word` 函数同样有效：

```rust,ignore
fn second_word(s: &String) -> &str {
```

我们现在有了一个简单直接的 API，更难出错，因为编译器将确保指向 `String` 的引用保持有效。还记得代码清单 4-8 中的那个 bug 吗？我们获得了第一个单词末尾的索引，然后清空了字符串，导致索引失效。那段代码在逻辑上是错误的，但没有立即显示任何错误。如果我们继续尝试对一个已清空的字符串使用第一个单词的索引，问题才会在后来暴露出来。Slice 使这个 bug 不可能发生，并让我们更早地知道代码存在问题。例如：

<span class="filename">文件名：src/main.rs</span>

```aquascope,permissions,boundaries,stepper,shouldFail
#fn first_word(s: &String) -> &str {
#    let bytes = s.as_bytes();
#
#    for (i, &item) in bytes.iter().enumerate() {
#        if item == b' ' {
#            return &s[0..i];
#        }
#    }
#
#    &s[..]
#}
fn main() {
    let mut s = String::from("hello world");
    let word = first_word(&s);`(focus,paths:s)`
    s.clear();`{}`
    println!("the first word is: {}", word);
}
```

可以看到，调用 `first_word` 现在会移除 `s` 的写权限，这阻止了我们调用 `s.clear()`。以下是编译器错误：

```console
{{#include ../listings/ch04-understanding-ownership/no-listing-19-slice-error/output.txt}}
```

回想借用规则：如果我们对某个东西有不可变引用，就不能同时获取可变引用。因为 `clear` 需要截断 `String`，它需要获取可变引用。`clear` 调用之后的 `println!` 使用了 `word` 中的引用，所以不可变引用在那时必须仍然有效。Rust 不允许 `clear` 中的可变引用与 `word` 中的不可变引用同时存在，因此编译失败。Rust 不仅使我们的 API 更易于使用，而且还在编译时消除了一整类错误！

#### 字符串字面量即 Slice

回想一下，我们曾提到字符串字面量存储在二进制文件内部。现在我们了解了 slice，就可以正确地理解字符串字面量了：

```rust
let s = "Hello, world!";
```

这里 `s` 的类型是 `&str`：它是一个指向二进制文件中特定位置的 slice。这也是字符串字面量不可变的原因；`&str` 是一个不可变引用。

#### 字符串 Slice 作为参数

了解到可以对字面量和 `String` 值取 slice 之后，我们可以对 `first_word` 做进一步改进，即改进它的签名：

```rust,ignore
fn first_word(s: &String) -> &str {
```

更有经验的 Rustacean 会编写代码清单 4-9 中所示的签名，因为它允许我们对 `&String` 值和 `&str` 值使用同一个函数。

```rust,ignore
{{#rustdoc_include ../listings/ch04-understanding-ownership/listing-04-09/src/main.rs:here}}
```

<span class="caption">代码清单 4-9：通过使用字符串 slice 作为 `s` 参数的类型来改进 `first_word` 函数</span>

如果我们有一个字符串 slice，可以直接传递它。如果我们有一个 `String`，可以传递 `String` 的 slice 或对 `String` 的引用。这种灵活性利用了*解引用强制转换*（deref coercions），这一特性我们将在第 15 章的["函数和方法的隐式解引用强制转换"][deref-coercions]<!--ignore-->一节中介绍。

将函数定义为接受字符串 slice 而非 `String` 引用，使我们的 API 更加通用和实用，且不会损失任何功能：

<span class="filename">文件名：src/main.rs</span>

```rust
{{#rustdoc_include ../listings/ch04-understanding-ownership/listing-04-09/src/main.rs:usage}}
```

### 其他 Slice

字符串 slice 顾名思义，是特定于字符串的。但还有一种更通用的 slice 类型。考虑这个数组：

```rust
let a = [1, 2, 3, 4, 5];
```

正如我们可能想引用字符串的一部分一样，我们也可能想引用数组的一部分。我们这样做：

```rust
let a = [1, 2, 3, 4, 5];

let slice = &a[1..3];

assert_eq!(slice, &[2, 3]);
```

这个 slice 的类型是 `&[i32]`。它的工作方式与字符串 slice 相同，都是通过存储对第一个元素的引用和长度来实现的。你将对各种其他集合使用这种 slice。我们将在第 8 章讨论向量时详细介绍这些集合。

{{#quiz ../quizzes/ch04-04-slices.toml}}

## 小结

Slice 是一种特殊的引用，指向序列（如字符串或向量）的子范围。在运行时，slice 表示为一个"胖指针"，包含指向范围起始位置的指针和范围的长度。与基于索引的范围相比，slice 的一个优势是在使用期间不会被无效化。

[ch13]: ch13-02-iterators.html
[ch6]: ch06-02-match.html#patterns-that-bind-to-values
[strings]: ch08-02-strings.html#storing-utf-8-encoded-text-with-strings
[deref-coercions]: ch15-02-deref.html#implicit-deref-coercions-with-functions-and-methods
