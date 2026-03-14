## 所有权回顾

本章介绍了许多新概念，如所有权、借用和 slice。如果你不熟悉系统编程，本章还介绍了内存分配、栈与堆、指针和未定义行为等新概念。在继续学习 Rust 的其余内容之前，让我们先停下来喘口气，回顾并练习本章的核心概念。

### 所有权与垃圾回收

为了将所有权放入语境理解，我们应该聊聊**垃圾回收**。大多数编程语言使用垃圾回收器来管理内存，例如 Python、Javascript、Java 和 Go。垃圾回收器在运行时与正在运行的程序并行工作（至少对于追踪式回收器而言）。回收器扫描内存以找到不再使用的数据——即正在运行的程序无法再从函数局部变量访问到的数据。然后回收器释放未使用的内存以供后续使用。

垃圾回收器的主要好处是避免未定义行为（例如使用已释放的内存），这在 C 或 C++ 中可能发生。垃圾回收还避免了像 Rust 那样使用复杂的类型系统来检查未定义行为的需要。然而，垃圾回收也有一些缺点。一个明显的缺点是性能，因为垃圾回收会带来频繁的小开销（对于引用计数，如 Python 和 Swift）或不频繁的大开销（对于追踪式回收，如所有其他 GC 语言）。

但另一个不那么明显的缺点是**垃圾回收可能是不可预测的**。为了说明这一点，假设我们正在实现一个 `Document` 类型，它表示一个可变的单词列表。我们可以用像 Python 这样的垃圾回收语言来实现 `Document`：

```python
class Document:
    def __init__(self, words: List[str]):
        """Create a new document"""
        self.words = words

    def add_word(self, word: str):
        """Add a word to the document"""
        self.words.append(word)

    def get_words(self) -> List[str]:
        """Get a list of all the words in the document"""
        return self.words
```

下面是我们使用这个 `Document` 类的一种方式：创建一个文档 `d`，将其复制到新文档 `d2`，然后修改 `d2`。

```python
words = ["Hello"]
d = Document(words)

d2 = Document(d.get_words())
d2.add_word("world")
```

关于这个例子，思考两个关键问题：

1. **words 数组何时被释放？**
这个程序创建了三个指向同一数组的指针。变量 `words`、`d` 和 `d2` 都包含指向堆上分配的 words 数组的指针。因此，Python 只有在所有三个变量都超出作用域时才会释放 words 数组。更一般地说，仅通过阅读源代码很难预测数据将在哪里被垃圾回收。

2. **文档 `d` 的内容是什么？**
因为 `d2` 包含指向与 `d` 相同 words 数组的指针，所以 `d2.add_word("world")` 也修改了文档 `d`。因此在这个例子中，`d` 中的单词是 `["Hello", "world"]`。这是因为 `d.get_words()` 返回了对 `d` 中 words 数组的可变引用。当数据结构可能泄漏其内部状态时，普遍存在的隐式可变引用很容易导致不可预测的 bug[^ownership-originally]。这里，对 `d2` 的更改影响到 `d` 可能并非预期行为。

这个问题并非 Python 独有——在 C#、Java、Javascript 等语言中也会遇到类似的行为。事实上，大多数编程语言确实有指针的概念，只是语言如何向程序员暴露指针的方式有所不同。垃圾回收使得很难看清哪个变量指向哪些数据。例如，`d.get_words()` 产生了指向 `d` 内部数据的指针，这一点并不明显。

相比之下，Rust 的所有权模型将指针置于核心位置。通过将 `Document` 类型翻译为 Rust 数据结构，我们可以清楚地看到这一点。通常我们会使用 `struct`，但我们还没有介绍它，所以这里只使用类型别名：

```rust
type Document = Vec<String>;

fn new_document(words: Vec<String>) -> Document {
    words
}

fn add_word(this: &mut Document, word: String) {
    this.push(word);
}

fn get_words(this: &Document) -> &[String] {
    this.as_slice()
}
```

这个 Rust API 与 Python API 在几个关键方面有所不同：

* 函数 `new_document` 消耗输入向量 `words` 的所有权。这意味着 `Document` *拥有* word 向量。当拥有它的 `Document` 超出作用域时，word 向量将被可预测地释放。

* 函数 `add_word` 需要可变引用 `&mut Document` 才能修改文档。它还消耗输入 `word` 的所有权，意味着没有人能修改文档中的单个词。

* 函数 `get_words` 返回文档中字符串的显式不可变引用。从这个 word 向量创建新文档的唯一方式是深复制其内容，如下所示：

```rust,ignore
fn main() {
    let words = vec!["hello".to_string()];
    let d = new_document(words);

    // .to_vec() converts &[String] to Vec<String> by cloning each string
    let words_copy = get_words(&d).to_vec();
    let mut d2 = new_document(words_copy);
    add_word(&mut d2, "world".to_string());

    // The modification to `d2` does not affect `d`
    assert!(!get_words(&d).contains(&"world".into()));
}
```

这个例子想说明的是：如果 Rust 不是你的第一门语言，那么你已经有了使用内存和指针的经验！Rust 只是让这些概念变得显式化。这带来了双重好处：(1) 通过避免垃圾回收提升运行时性能；(2) 通过防止意外的数据"泄漏"提升可预测性。

### 所有权的概念

接下来，让我们回顾所有权的概念。这次回顾会很简短——目标是提醒你相关概念。如果你发现自己忘记或没有理解某个概念，我们会链接到相关章节供你复习。

#### 运行时的所有权

我们先回顾 Rust 在运行时如何使用内存：
* Rust 在栈帧中分配局部变量，栈帧在函数调用时分配，在调用结束时释放。
* 局部变量可以持有数据（如数字、布尔值、元组等）或指针。
* 指针可以通过 Box（拥有堆上数据的指针）或引用（非所有权指针）来创建。

下图说明了每个概念在运行时的样子：

```aquascope,interpreter,horizontal
fn main() {
  let mut a_num = 0;
  inner(&mut a_num);`[]`
}

fn inner(x: &mut i32) {
  let another_num = 1;
  let a_stack_ref = &another_num;

  let a_box = Box::new(2);
  let a_box_stack_ref = &a_box;
  let a_box_heap_ref = &*a_box;`[]`

  *x += 5;
}
```

仔细查看这张图，确保你理解每个部分。例如，你应该能回答：
* 为什么 `a_box_stack_ref` 指向栈，而 `a_box_heap_ref` 指向堆？
* 为什么在 L2 时值 `2` 不再在堆上？
* 为什么在 L2 时 `a_num` 的值是 `5`？

如果想复习 Box，请重新阅读[第 4.1 章][ch04-01]。如果想复习引用，请重新阅读[第 4.2 章][ch04-02]。如果想查看涉及 Box 和引用的案例研究，请重新阅读[第 4.3 章][ch04-03]。

Slice 是一种特殊的引用，指向内存中连续的数据序列。下图说明了 slice 如何引用字符串中字符的子序列：

```aquascope,interpreter
fn main() {
  let s = String::from("abcdefg");
  let s_slice = &s[2..5];`[]`
}
```

如果想复习 slice，请重新阅读[第 4.4 章][ch04-04]。


#### 编译时的所有权

Rust 跟踪每个变量的 @Perm{read}（读）、@Perm{write}（写）和 @Perm{own}（拥有）权限。Rust 要求变量拥有适当的权限才能执行给定的操作。一个基本例子是，如果变量没有用 `let mut` 声明，它就缺少 @Perm{write} 权限，无法被修改：

```aquascope,permissions,stepper,boundaries,shouldFail
fn main() {
  let n = 0;
  n += 1;
}
```

变量的权限可以在**移动**或**借用**时改变。移动一个非可复制类型（如 `Box<T>` 或 `String`）的变量需要 @Perm{read}@Perm{own} 权限，移动后该变量上的所有权限都被消除。这一规则防止了对已移动变量的使用：

```aquascope,permissions,stepper,boundaries,shouldFail
fn main() {
  let s = String::from("Hello world");
  consume_a_string(s);
  println!("{s}"); // can't read `s` after moving it
}

fn consume_a_string(_s: String) {
  // om nom nom
}
```

如果想复习移动的工作原理，请重新阅读[第 4.1 章][ch04-01]。

借用一个变量（创建对它的引用）会暂时移除该变量的某些权限。不可变借用创建不可变引用，同时禁止被借用数据被修改或移动。例如，打印不可变引用是可以的：

```aquascope,permissions,stepper,boundaries
#fn main() {
let mut s = String::from("Hello");
let s_ref = &s;
println!("{s_ref}");
println!("{s}");
#}
```

但修改不可变引用是不允许的：

```aquascope,permissions,stepper,boundaries,shouldFail
#fn main() {
let mut s = String::from("Hello");
let s_ref = &s;`(focus,paths:*s_ref)`
s_ref.push_str(" world");
println!("{s}");
#}
```

修改被不可变借用的数据也是不允许的：

```aquascope,permissions,stepper,boundaries,shouldFail
#fn main() {
let mut s = String::from("Hello");`(focus)`
let s_ref = &s;`(focus,rxpaths:s$)`
s.push_str(" world");
println!("{s_ref}");
#}
```

从引用中移动数据也是不允许的：

```aquascope,permissions,stepper,boundaries,shouldFail
#fn main() {
let mut s = String::from("Hello");
let s_ref = &s;`(focus,paths:*s_ref)`
let s2 = *s_ref;
println!("{s}");
#}
```

可变借用创建可变引用，这会禁止被借用数据被读取、写入或移动。例如，通过可变引用进行修改是可以的：

```aquascope,permissions,stepper,boundaries
#fn main() {
let mut s = String::from("Hello");
let s_ref = &mut s;
s_ref.push_str(" world");
println!("{s}");
#}
```

但访问被可变借用的数据是不允许的：

```aquascope,permissions,stepper,boundaries,shouldFail
#fn main() {
let mut s = String::from("Hello");
let s_ref = &mut s;`(focus,rxpaths:s$)`
println!("{s}");
s_ref.push_str(" world");
#}
```

如果想复习权限和引用，请重新阅读[第 4.2 章][ch04-02]。

#### 连接编译时与运行时的所有权

Rust 的权限系统旨在防止未定义行为。例如，一种未定义行为是**释放后使用**（use-after-free），即读取或写入已释放的内存。不可变借用移除 @Perm{write} 权限以避免释放后使用，如以下情况：

```aquascope,interpreter,shouldFail,horizontal
#fn main() {
let mut v = vec![1, 2, 3];
let n = &v[0];`[]`
v.push(4);`[]`
println!("{n}");`[]`
#}
```

另一种未定义行为是**双重释放**（double-free），即内存被释放两次。对非可复制数据的引用解引用没有 @Perm{own} 权限，以避免双重释放，如以下情况：

```aquascope,interpreter,shouldFail,horizontal
#fn main() {
let v = vec![1, 2, 3];
let v_ref: &Vec<i32> = &v;
let v2 = *v_ref;`[]`
drop(v2);`[]`
drop(v);`[]`
#}
```

如果想复习未定义行为，请重新阅读[第 4.1 章][ch04-01]和[第 4.3 章][ch04-03]。


### 所有权的其余内容

随着我们介绍结构体、枚举和 trait 等其他特性，这些特性将与所有权产生特定的交互。本章为理解这些交互奠定了必要的基础——内存、指针、未定义行为和权限的概念将帮助我们在后续章节中讨论 Rust 更高级的部分。

别忘了做测验，以检验你的理解！

{{#quiz ../quizzes/ch04-05-ownership-recap.toml}}



[^ownership-originally]: 事实上，所有权类型的最初发明与内存安全毫无关系。它是为了防止在类 Java 语言中可变引用泄漏数据结构内部状态。如果你对所有权类型的历史感到好奇，可以查阅论文["Ownership Types for Flexible Alias Protection"](https://dl.acm.org/doi/abs/10.1145/286936.286947)（Clarke et al. 1998）。

[ch04-01]: ch04-01-what-is-ownership.html
[ch04-02]: ch04-02-references-and-borrowing.html
[ch04-03]: ch04-03-fixing-ownership-errors.html
[ch04-04]: ch04-04-slices.html
