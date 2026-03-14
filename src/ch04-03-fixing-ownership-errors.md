## 修复所有权错误

学会修复所有权错误是 Rust 的核心技能。当借用检查器拒绝你的代码时，该如何应对？本节将通过几个常见所有权错误的案例研究来加以说明。每个案例都会给出一个被编译器拒绝的函数，并解释 Rust 拒绝它的原因，以及若干修复方式。

贯穿始终的主题是：判断一段程序**实际上**是安全的还是不安全的。Rust 总会拒绝不安全的程序[^safe-subset]。但有时，Rust 也会拒绝安全的程序。这些案例将展示在两种情况下如何应对错误。

<!-- The last two sections have shown how a Rust program can be **unsafe** if it triggers undefined behavior. The ownership guarantee is that Rust will reject all unsafe programs. However, Rust will also reject *some* safe programs. Fixing an ownership error will depend on whether your program is *actually* safe or unsafe. -->

### 修复不安全程序：返回栈上的引用

第一个案例是返回栈上数据的引用，就像上一节["数据必须比其所有引用存活得更长"](ch04-02-references-and-borrowing.html#data-must-outlive-all-of-its-references)中讨论的那样。下面是我们看过的函数：

```rust,ignore,does_not_compile
fn return_a_string() -> &String {
    let s = String::from("Hello world");
    &s
}
```

思考如何修复这个函数时，需要先问：**为什么这个程序不安全？** 这里的问题在于被引用数据的生命周期。如果你想传递一个字符串的引用，必须确保底层字符串存活得足够长。

根据不同的情况，以下是四种延长字符串生命周期的方式。第一种是将字符串的所有权移出函数，把返回类型从 `&String` 改为 `String`：

```rust
fn return_a_string() -> String {
    let s = String::from("Hello world");
    s
}
```

另一种可能是返回一个字符串字面量，它永远存活（用 `'static` 表示）。如果我们从不打算修改这个字符串，那么堆分配是不必要的，这种方案就很适合：

```rust
fn return_a_string() -> &'static str {
    "Hello world"
}
```

还有一种可能是通过垃圾回收将借用检查推迟到运行时。例如，可以使用[引用计数指针][rc]：

```rust
use std::rc::Rc;
fn return_a_string() -> Rc<String> {
    let s = Rc::new(String::from("Hello world"));
    Rc::clone(&s)
}
```

我们将在第 15.4 章["`Rc<T>`，引用计数智能指针"](ch15-04-rc.html)中进一步讨论引用计数。简而言之，`Rc::clone` 只克隆一个指向 `s` 的指针，而非数据本身。运行时，当最后一个指向数据的 `Rc` 被丢弃时，`Rc` 会自动释放数据。

还有一种可能是让调用者通过可变引用提供一个"槽位"来存放字符串：

```rust
fn return_a_string(output: &mut String) {
    output.replace_range(.., "Hello world");
}
```

这种策略将创建字符串空间的责任交给调用者。这种写法可能稍显冗长，但如果调用者需要精确控制内存分配时机，它也能更节省内存。

哪种策略最合适取决于具体应用场景。但核心思路是找到表层所有权错误背后的根本原因：我的字符串应该存活多久？谁负责释放它？一旦对这些问题有了清晰的答案，就只需要调整 API 使其与答案相符。


### 修复不安全程序：权限不足

另一个常见问题是试图修改只读数据，或者试图丢弃引用背后的数据。例如，假设我们尝试编写函数 `stringify_name_with_title`，它应该从一个名字部分的向量创建一个完整姓名，并附加一个额外头衔。

```aquascope,permissions,stepper,boundaries,shouldFail
fn stringify_name_with_title(name: &Vec<String>) -> String {
    name.push(String::from("Esq."));`{}`
    let full = name.join(" ");
    full
}

// ideally: ["Ferris", "Jr."] => "Ferris Jr. Esq."
```

这段程序被借用检查器拒绝，因为 `name` 是不可变引用，而 `name.push(..)` 需要 @Perm{write} 权限。这个程序不安全，因为 `push` 可能使 `stringify_name_with_title` 外部其他指向 `name` 的引用失效，如下所示：

```aquascope,interpreter,shouldFail,horizontal
#fn stringify_name_with_title(name: &Vec<String>) -> String {
#    name.push(String::from("Esq."));
#    let full = name.join(" ");
#    full
#}
fn main() {
    let name = vec![String::from("Ferris")];
    let first = &name[0];`[]`
    stringify_name_with_title(&name);`[]`
    println!("{}", first);`[]`
}
```

在这个例子中，调用 `stringify_name_with_title` 之前，先创建了指向 `name[0]` 的引用 `first`。函数中的 `name.push(..)` 会重新分配 `name` 的内容，使 `first` 失效，导致 `println` 读取已释放的内存。

那么如何修复这个 API？一个直接的方案是将 `name` 的类型从 `&Vec<String>` 改为 `&mut Vec<String>`：

```rust,ignore
fn stringify_name_with_title(name: &mut Vec<String>) -> String {
    name.push(String::from("Esq."));
    let full = name.join(" ");
    full
}
```

但这并不是好方案！**函数不应该在调用者不期望的情况下修改其输入。** 调用 `stringify_name_with_title` 的人很可能不希望这个函数修改他们的向量。像 `add_title_to_name` 这样的函数可能被预期会修改输入，但我们的函数不应如此。

另一个选项是通过将 `&Vec<String>` 改为 `Vec<String>` 来获取 `name` 的所有权：

```rust,ignore
fn stringify_name_with_title(mut name: Vec<String>) -> String {
    name.push(String::from("Esq."));
    let full = name.join(" ");
    full
}
```

但这同样不是好方案！**Rust 函数很少获取 `Vec` 和 `String` 这类拥有堆数据的数据结构的所有权。** 这个版本的 `stringify_name_with_title` 会使输入的 `name` 无法继续使用，这对调用者来说非常不便，正如我们在["引用与借用"](ch04-02-references-and-borrowing.html)开头所讨论的。

所以选择 `&Vec` 实际上是正确的，我们*不*想改变它。相反，我们可以修改函数体。有许多可能的修复方式，内存消耗各有不同。一种可能是克隆输入的 `name`：

```rust,ignore
fn stringify_name_with_title(name: &Vec<String>) -> String {
    let mut name_clone = name.clone();
    name_clone.push(String::from("Esq."));
    let full = name_clone.join(" ");
    full
}
```

通过克隆 `name`，我们可以对向量的本地副本进行修改。但是，克隆会复制输入中的每个字符串。我们可以通过在后面添加后缀来避免不必要的复制：

```rust,ignore
fn stringify_name_with_title(name: &Vec<String>) -> String {
    let mut full = name.join(" ");
    full.push_str(" Esq.");
    full
}
```

这个方案可行，因为 [`slice::join`] 已经将 `name` 中的数据复制到了字符串 `full` 中。

总体而言，编写 Rust 函数是一种微妙的平衡——请求*恰当*级别的权限。对于这个例子，最惯用的做法是只要求对 `name` 的读取权限。

{{#quiz ../quizzes/ch04-03-fixing-ownership-errors-sec1-idioms.toml}}

### 修复不安全程序：对数据结构的别名引用与修改

另一种不安全操作是使用指向堆数据的引用，而该数据被另一个别名释放。例如，下面的函数获取向量中最长字符串的引用，然后在修改向量的同时使用该引用：

```aquascope,permissions,stepper,boundaries,shouldFail
fn add_big_strings(dst: &mut Vec<String>, src: &[String]) {`(focus,paths:*dst)`
    let largest: &String =
      dst.iter().max_by_key(|s| s.len()).unwrap();`(focus,paths:*dst)`
    for s in src {
        if s.len() > largest.len() {
            dst.push(s.clone());`{}`
        }
    }
}
```

> *注意：* 本例使用了[迭代器][iterators]和[闭包][closures]来简洁地找到最长字符串的引用。我们将在后续章节中讨论这些特性，这里只需直观地理解它们的用法。

这段程序被借用检查器拒绝，因为 `let largest = ..` 移除了 `dst` 的 @Perm{write} 权限，而 `dst.push(..)` 需要 @Perm{write} 权限。再次问：**为什么这个程序不安全？** 因为 `dst.push(..)` 可能释放 `dst` 的内容，使引用 `largest` 失效。

修复这个程序的关键思路是：缩短 `largest` 的借用生命周期，使其不与 `dst.push(..)` 重叠。一种可能是克隆 `largest`：

```rust
fn add_big_strings(dst: &mut Vec<String>, src: &[String]) {
    let largest: String = dst.iter().max_by_key(|s| s.len()).unwrap().clone();
    for s in src {
        if s.len() > largest.len() {
            dst.push(s.clone());
        }
    }
}
```

但这可能带来分配和复制字符串数据的性能损耗。

另一种可能是先完成所有长度比较，然后再修改 `dst`：

```rust
fn add_big_strings(dst: &mut Vec<String>, src: &[String]) {
    let largest: &String = dst.iter().max_by_key(|s| s.len()).unwrap();
    let to_add: Vec<String> =
        src.iter().filter(|s| s.len() > largest.len()).cloned().collect();
    dst.extend(to_add);
}
```

但这也会因分配向量 `to_add` 带来性能损耗。

最后一种可能是直接复制 `largest` 的长度，因为我们实际上不需要 `largest` 的内容，只需要它的长度。这个方案可以说是最惯用也是性能最好的：

```rust
fn add_big_strings(dst: &mut Vec<String>, src: &[String]) {
    let largest_len: usize = dst.iter().max_by_key(|s| s.len()).unwrap().len();
    for s in src {
        if s.len() > largest_len {
            dst.push(s.clone());
        }
    }
}
```

这些方案都有一个共同的核心思路：缩短对 `dst` 的借用生命周期，使其不与对 `dst` 的修改重叠。

### 修复不安全程序：从集合中复制 vs. 移动

Rust 初学者常见的困惑是从集合（如向量）中复制数据时的行为。例如，下面是一个安全地从向量中复制数字的程序：

```aquascope,permissions,stepper,boundaries
#fn main() {
let v: Vec<i32> = vec![0, 1, 2];
let n_ref: &i32 = &v[0];`(focus,paths:*n_ref)`
let n: i32 = *n_ref;`{}`
#}
```

解引用操作 `*n_ref` 只需要 @Perm{read} 权限，而路径 `*n_ref` 正好拥有该权限。但如果把向量中元素的类型从 `i32` 改为 `String` 呢？这时我们就不再拥有必要的权限了：

```aquascope,permissions,stepper,boundaries,shouldFail
#fn main() {
let v: Vec<String> =
  vec![String::from("Hello world")];
let s_ref: &String = &v[0];`(focus,paths:*s_ref)`
let s: String = *s_ref;`[]``{}`
#}
```

第一个程序可以编译，但第二个程序无法编译。Rust 给出如下错误信息：

```text
error[E0507]: cannot move out of `*s_ref` which is behind a shared reference
 --> test.rs:4:9
  |
4 | let s = *s_ref;
  |         ^^^^^^
  |         |
  |         move occurs because `*s_ref` has type `String`, which does not implement the `Copy` trait
```

问题在于向量 `v` 拥有字符串 "Hello world"。当我们解引用 `s_ref` 时，试图从向量中获取字符串的所有权。但引用是非所有权指针——我们无法*通过*引用获取所有权。因此 Rust 报告"无法从共享引用中移动"。

但为什么这是不安全的？我们可以通过模拟被拒绝的程序来说明问题：

```aquascope,interpreter,shouldFail,horizontal
#fn main() {
let v: Vec<String> =
  vec![String::from("Hello world")];
let s_ref: &String = &v[0];`(focus,paths:*s_ref)`
let s: String = *s_ref;`[]``{}`

// These drops are normally implicit, but we've added them for clarity.
drop(s);`[]`
drop(v);`[]`
#}
```

这里发生了**双重释放**。执行 `let s = *s_ref` 后，`v` 和 `s` 都认为自己拥有 "Hello world"。`s` 被丢弃后，"Hello world" 被释放。然后 `v` 被丢弃，字符串被第二次释放，发生未定义行为。

> *注意：* 执行 `s = *s_ref` 后，即使不使用 `v` 或 `s`，双重释放也会导致未定义行为。一旦我们将字符串从 `s_ref` 中移出，元素被丢弃时就会发生未定义行为。

但当向量包含 `i32` 元素时，这种未定义行为不会发生。区别在于复制 `String` 会复制一个指向堆数据的指针，而复制 `i32` 则不会。用技术术语来说，Rust 表示类型 `i32` 实现了 `Copy` trait，而 `String` 没有实现 `Copy`（我们将在后续章节讨论 trait）。

总结：**如果一个值不拥有堆数据，它就可以在不移动的情况下被复制。** 例如：

* `i32` **不**拥有堆数据，因此**可以**在不移动的情况下复制。
* `String` **拥有**堆数据，因此**不能**在不移动的情况下复制。
* `&String` **不**拥有堆数据，因此**可以**在不移动的情况下复制。

> *注意：* 这条规则有一个例外，即可变引用。例如，`&mut i32` 不是可复制类型。所以如果你这样写：
> ```rust,ignore
> let mut n = 0;
> let a = &mut n;
> let b = a;
> ```
> 那么 `a` 在被赋值给 `b` 之后就不能再使用了。这防止了同时使用指向同一数据的两个可变引用。

那么，如果我们有一个包含非 `Copy` 类型（如 `String`）的向量，如何安全地访问其中的元素？以下是几种安全的方式。第一种，避免获取字符串的所有权，只使用不可变引用：

```rust,ignore
# fn main() {
let v: Vec<String> = vec![String::from("Hello world")];
let s_ref: &String = &v[0];
println!("{s_ref}!");
# }
```

第二种，如果你想获取字符串的所有权同时保持向量不变，可以克隆数据：

```rust,ignore
# fn main() {
let v: Vec<String> = vec![String::from("Hello world")];
let mut s: String = v[0].clone();
s.push('!');
println!("{s}");
# }
```

最后，可以使用 [`Vec::remove`] 等方法将字符串从向量中移出：

```rust,ignore
# fn main() {
let mut v: Vec<String> = vec![String::from("Hello world")];
let mut s: String = v.remove(0);
s.push('!');
println!("{s}");
assert!(v.len() == 0);
# }
```


### 修复安全程序：修改不同的元组字段

以上例子都是程序不安全的情况。Rust 也可能拒绝安全的程序。一个常见问题是 Rust 试图在细粒度级别跟踪权限，但有时会将两个不同的位置混为一谈。

首先来看一个能通过借用检查器的细粒度权限跟踪示例。这个程序展示了如何借用元组的一个字段，同时写入同一元组的另一个字段：

```aquascope,permissions,stepper,boundaries
#fn main() {
let mut name = (
    String::from("Ferris"),
    String::from("Rustacean")
);`(focus,paths:name)`
let first = &name.0;`(focus,paths:name)`
name.1.push_str(", Esq.");`{}`
println!("{first} {}", name.1);
#}
```

语句 `let first = &name.0` 借用了 `name.0`。这次借用移除了 `name.0` 的 @Perm{write}@Perm{own} 权限，同时也移除了 `name` 的 @Perm{write}@Perm{own} 权限。（例如，不能将 `name` 传递给接受 `(String, String)` 类型值的函数。）但 `name.1` 仍然保留了 @Perm{write} 权限，因此 `name.1.push_str(...)` 是合法操作。

然而，Rust 有时会失去对被借用位置的精确追踪。例如，假设我们将表达式 `&name.0` 重构为函数 `get_first`。注意，调用 `get_first(&name)` 后，Rust 现在移除了 `name.1` 的 @Perm{write} 权限：

```aquascope,permissions,stepper,boundaries,shouldFail
fn get_first(name: &(String, String)) -> &String {
    &name.0
}

fn main() {
    let mut name = (
        String::from("Ferris"),
        String::from("Rustacean")
    );
    let first = get_first(&name);`(focus,paths:name)`
    name.1.push_str(", Esq.");`{}`
    println!("{first} {}", name.1);
}
```

现在 `name.1.push_str(..)` 不被允许了！Rust 会返回如下错误：

```text
error[E0502]: cannot borrow `name.1` as mutable because it is also borrowed as immutable
  --> test.rs:11:5
   |
10 |     let first = get_first(&name);
   |                           ----- immutable borrow occurs here
11 |     name.1.push_str(", Esq.");
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^ mutable borrow occurs here
12 |     println!("{first} {}", name.1);
   |                ----- immutable borrow later used here
```

这很奇怪，因为编辑之前程序是安全的。我们所做的编辑并没有实质性地改变运行时行为。那么，为什么将 `&name.0` 放入函数中会有影响？

问题在于，Rust 在决定 `get_first(&name)` 应该借用什么时，并不查看 `get_first` 的实现。Rust 只看类型签名，而类型签名只说"输入中的某个 `String` 被借用了"。Rust 于是保守地认为 `name.0` 和 `name.1` 都被借用，并同时移除了两者的写入和所有权限。

记住，关键点是：**上面的程序是安全的。** 它没有未定义行为！未来版本的 Rust 可能足够智能，允许它编译，但目前它会被拒绝。那么今天如何绕过借用检查器呢？一种可能是内联表达式 `&name.0`，就像原始程序那样。另一种可能是通过 [cells] 将借用检查推迟到运行时，我们将在后续章节中讨论。

### 修复安全程序：修改不同的数组元素

当我们借用数组的元素时，会出现类似的问题。例如，观察当我们对数组取可变引用时，哪些位置被借用：

```aquascope,permissions,stepper,boundaries
#fn main() {
let mut a = [0, 1, 2, 3];
let x = &mut a[1];`(focus,paths:a[_])`
*x += 1;`(focus,paths:a[_])`
println!("{a:?}");
#}
```

Rust 的借用检查器对 `a[0]`、`a[1]` 等不区分不同的位置。它使用单一位置 `a[_]` 来表示 `a` 的*所有*索引。Rust 这样做是因为它不总能确定索引的值。例如，想象一个更复杂的场景：

```rust,ignore
let idx = a_complex_function();
let x = &mut a[idx];
```

`idx` 的值是什么？Rust 不会去猜测，所以它假设 `idx` 可以是任何值。例如，假设我们试图在写入一个数组索引的同时读取另一个索引：

```aquascope,permissions,boundaries,stepper,shouldFail
#fn main() {
let mut a = [0, 1, 2, 3];
let x = &mut a[1];`(focus,paths:a[_])`
let y = &a[2];`{}`
*x += *y;
#}
```

Rust 会拒绝这段程序，因为 `a` 已将读取权限借给了 `x`。编译器的错误信息也这样说：

```text
error[E0502]: cannot borrow `a[_]` as immutable because it is also borrowed as mutable
 --> test.rs:4:9
  |
3 | let x = &mut a[1];
  |         --------- mutable borrow occurs here
4 | let y = &a[2];
  |         ^^^^^ immutable borrow occurs here
5 | *x += *y;
  | -------- mutable borrow later used here
```

<!-- However, Rust will reject this program because `a` gave its read permission to `x`. -->


同样，**这个程序是安全的。** 对于这类情况，Rust 通常在标准库中提供了可以绕过借用检查器的函数。例如，我们可以使用 [`slice::split_at_mut`][split_at_mut]：

```rust,ignore
# fn main() {
let mut a = [0, 1, 2, 3];
let (a_l, a_r) = a.split_at_mut(2);
let x = &mut a_l[1];
let y = &a_r[0];
*x += *y;
# }
```

你可能好奇，`split_at_mut` 是如何实现的？在某些 Rust 库中，尤其是像 `Vec` 或 `slice` 这样的核心类型中，经常能看到 **`unsafe` 块**。`unsafe` 块允许使用"裸"指针，这些指针不受借用检查器的安全检查。例如，我们可以用 unsafe 块完成我们的任务：

```rust,ignore
# fn main() {
let mut a = [0, 1, 2, 3];
let x = &mut a[1] as *mut i32;
let y = &a[2] as *const i32;
unsafe { *x += *y; } // DO NOT DO THIS unless you know what you're doing!
# }
```

有时需要使用 unsafe 代码来绕过借用检查器的限制。作为一般策略，如果借用检查器拒绝了你认为实际上安全的程序，那么应该寻找标准库中包含 `unsafe` 块的函数（如 `split_at_mut`）来解决你的问题。我们将在[第 20 章][unsafe]中进一步讨论 unsafe 代码。现在只需知道，unsafe 代码是 Rust 实现某些否则不可能的模式的方式。

{{#quiz ../quizzes/ch04-03-fixing-ownership-errors-sec2-safety.toml}}

### 小结

修复所有权错误时，应该先问自己：我的程序实际上是不安全的吗？如果是，则需要理解不安全性的根本原因。如果不是，则需要理解借用检查器的局限性，并想办法绕过它。

[rc]: https://doc.rust-lang.org/std/rc/index.html
[cells]: https://doc.rust-lang.org/std/cell/index.html
[split_at_mut]: https://doc.rust-lang.org/std/primitive.slice.html#method.split_at_mut
[unsafe]: ch19-01-unsafe-rust.html
[`Vec::remove`]: https://doc.rust-lang.org/std/vec/struct.Vec.html#method.remove
[`slice::join`]: https://doc.rust-lang.org/std/primitive.slice.html#method.join
[iterators]: ch13-02-iterators.html
[closures]: ch13-01-closures.html

[^safe-subset]: 这一保证适用于以 Rust "安全子集"编写的程序。如果使用了 `unsafe` 代码或调用了不安全组件（如调用 C 库），则必须格外小心，避免未定义行为。
