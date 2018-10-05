## 参照

改めて説明しますが、ポインタ(ポインタ型変数)とは、オブジェクトのメモリ上の位置、すなわちアドレスをデータとして格納する変数です。
ポインタは C 言語でも使いますし、解説もたくさんありますので、これ以上はここで説明しません。

参照は、プログラミングをする上で実質的にポインタに似た性質を持つものであると見なして構いません。
C++ に慣れた人はポインタよりも参照を多用します。


### 参照の使い方

参照は、ポインタと同様に、あるオブジェクトを指しているだけですが、ポインタと違って、値型変数と同様の操作ができます。

`A` というユーザー定義型があったとします。

```c++
A a;  // normal variable
A& ref = a;  // reference variable
A* ptr = &a;  // pointer variable

ref.func();
ptr->func();  // ptr が nullptr だと不定動作

A* ptr2 = &ref;  // 参照変数のアドレスも取れる

// ref = nullptr; // 不可能
ptr = nullptr;
```

参照 `ref` は `.` 演算子でメンバにアクセスできますが、ポインタ `ptr` は、それが実在するオブジェクトを指しているときに限り `->` でアクセスする必要があります。
もしくは明示的に dereference して `(*ptr).func();` などとアクセスできます。
参照は、値型変数と同様に `&` でアドレスも取れます。
参照は、その宣言時に必ず初期化を必要とし、実在するオブジェクトを必要とするだけでなく、参照先を後から変更することもできません(再代入不可能)。
つまり、参照は常に初期化時に指定されたオブジェクトを指しています。
ポインタは宣言と初期化を分離できますし、代入によって自由に指すオブジェクトを変えることができますし、`nullptr` を格納できる点が異なります。
そうです、参照は `nullptr` を保持できません。
つまり、どのオブジェクトも指していない、という状態を表現できません。
表現力という点において参照はポインタに劣るのです。
だがそれが良いのです。
別の言い方をすると、参照は、dereference が保証されたポインタのように振る舞うとも言えます。


### 参照の価値

ポインタよりも参照を使いたくなる典型的な例を以下に挙げます。

```c++
void func(A* p)
{
    if (p == nullptr) {
        // error 処理
    }
    // *p により A 型オブジェクトにアクセスできる。
}

void func(A& a)
{
    // nullptr チェック不要。a を値型変数のように扱って良い。
}
```
`void func(A& a)` は関数シグネチャを見れば `nullptr` を渡せないのは明らかで、内部での `nullptr` チェックが不要になります。
だから `func()` が、`A` の実体を必ず必要とする場合には、参照渡しをすべきです。
逆に、`nullptr` であることに意味を持たせる場合、例えば、「A のデータがない」という意味を持たせ、`func()` がそれを許容する、`nullptr` のときでも通常処理を行えるような場合は、ポインタ渡しの `void func(A* p)` を選択する意味があると思います。

メンバ関数がメンバ変数のポインタか参照を返したいと思ったときに、どちらで返すのが良いでしょうか。
これも関数の仮引数のときと同じ考え方で決めれば良いと思います。
つまり、ポインタで返す場合は、`nullptr` が返ることに意味が持たせてある場合のみにすべきです。
呼出し側は `nullptr` が返ったときでも通常処理を行うような場合です。
逆に` nullptr` が絶対に返らないなら、ポインタではなく参照を返すインターフェースにすべきです。
そうでないと、呼出し側は絶対に返らないはずの `nullptr` が返るかも知れないと思って無駄な分岐処理を書いてしまうかも知れません。
少なくとも関数シグネチャを見ただけでは `nullptr` が返らないことは分かりません。
参照返しのインターフェースならそれは一目瞭然ですね。

参照渡しとポインタ渡し、参照返しとポインタ返しの使い分けをしっかりすることが、
C++ で書かれたコードの可読性、メンテナンス性に大きな影響を与えると思います。


### コピーセマンティクス

コピーセマンティクスの目的は、オブジェクトを安全にコピーできるようにすることです。
一般に、オブジェクトがコピー可能 (Copyable) であるときは、コピーコンストラクタとコピー代入演算子が定義されていて、それらの挙動はコピーであること、すなわち異なるオブジェクトだが内容が同じであることが期待されています。

```c++
struct V
{
    std::vector<char> v;
    V(size_t s) : v(s) {}
};

int main()
{
    V v0(10);
    V v1 = v0;  // コピーコンストラクタが呼ばれる
    v1 = v0;  // コピー代入演算子が呼ばれる
}
```
メンバ変数が全て Copyable である型はデフォルトで Copyable になります。
`std::vector<char>` は Copyable です。
つまり、上記の型 `V` は Copyable です。

以下の `C` のようなクラスが自分で作る典型的な Copyable class です。

```c++
struct C  // Copyable class example
{
    // Default constructor
    C() = default;
    // Copy constructor
    C(const C& rhs) : C() { copy(rhs); }
    // Copy assign operator
    C& operator=(const C& rhs) { copy(rhs); return *this; }
    void copy(const C& rhs) {
        // rhs の中身を *this にコピー
    }
    C(C&&) = delete;
    C& operator=(C&&) = delete;
};
```
`copy()` 関数は、コピー操作の実装です。通常は、メンバ変数を全部をコピーすることが求められます。

Copyable class は以下のように使えます。

```c++
void f(const C& c)
{
    // c を read-only アクセスする
}

void g(C& c)
{
    // c を操作する
}

struct A
{
    C c;
    const C& ref() const { return c; }  // const lvalue reference を返す
    C& ref() { return c; }  // lvalue reference を返す
};

int main()
{
    C c0;
    C c1 = c0;  // copy constructor が呼ばれる
    C c2;
    c2 = c1;  // copy assign operator が呼ばれる
    f(c0);
    g(c1);
    A a;
    const C& c3 = a.ref();  // const 版が呼ばれる
    C& c4 = a.ref();  // non-const 版が呼ばれる
    C c5 = a.ref();  // const 版、copy constructor が呼ばれる
    c5 = a.ref(); // const 版、copy assign operator が呼ばれる
}
```

`A::ref()` はオーバーロードされていてふたつの実体があり、引数や返り値に応じて適切なものが呼ばれます。

ポインタをメンバ変数に持つクラスを Copyable にするのは注意が必要です。

```c++
struct NC
{
    char *p_;
    NC(size_t s) : p_(new char[s]) {}
    ~NC() { delete[] p_; }
    NC(const NC&) = default;
    NC& operator=(const NC&) = default;
};

int main()
{
    NC nc1(10);
    NC nc2 = nc1;  // copy construcor が呼ばれる
} // double free してしまうバグ
```
上の例 `NC` では、敢えて `default` でコピーコンストラクタとコピー代入演算子を明示していますが、何も書かなくても定義されます。
デフォルトのコピー実装は、ポインタを単にコピーしてしまいます。
`p_` を単にコピーすると、2 つの `NC` 型オブジェクトが同一のヒープオブジェクトを指してしまいます。
これは多くの場合、我々がコピーの挙動として期待するものとは異なります。
このようなケースでは、ヒープオブジェクトを別途確保して内容をコピーするコードを自分で実装するか、参照カウンタなどでコピーとして見做せるよう実装するか、明示的にコピーを禁止するべきです。
ヒープオブジェクトを確保するコードを自分で実装してみます。この例では生ポインタを使いましたが、`std::unique_ptr` を使うべきです。

```c++
struct NC
{
    std::unique_ptr<char[]> p_;
    size_t s_;
    NC(size_t s) : p_(new char[s]), s_(s) {}
    NC(const NC& rhs) : p_(), s_(0) { copy(rhs); }
    NC& operator=(const NC& rhs) { copy(rhs); return *this; }
    void copy(const NC& rhs) {
        if (s_ < rhs.s_) {
            p_.reset(new char[rhs.s_]);
        }
        ::memcpy(p_.get(), rhs.p_.get(), rhs.s_);
        s_ = rhs.s_;
    }
};

int main()
{
    NC nc1(10);
    NC nc2 = nc1;  // copy construcor が呼ばれる
    nc2 = nc1;  // copy assign operator が呼ばれる
}
```
明示的にコピーを禁止するには、`NC(const NC&) = delete;` および  `NC& operator=(const NC&) = delete;` と定義します。


### ムーヴセマンティクス

C++11 で、ムーヴセマンティクスが導入されました。
ムーヴセマンティクスの目的は、オブジェクトを安全にムーヴすることです。
ムーヴとは、移譲とか、中身の移動、という操作を指します。
これを所有権の移動と捉えても良いかと思います。
先の `NC` 型は、単純にはコピーできない型でした。しかし、このような型でもムーヴならできます。

```c++
struct NC
{
    std::unique_ptr<char[]> p_;
    NC(size_t s) : p_(new char[s]) {}
};

{
    NC nc1(5);
    // NC nc2 = nc1;  // コピーできない
    NC nc2 = std::move(nc1); // ムーヴはできる
    // nc1 が持っていたデータは nc2 に移譲された
}
```
メンバ変数が全てムーヴ可能な型はデフォルトでムーヴ可能となります。
`std::unique_ptr` はコピーできないがムーヴできる型です。
つまり、この `NC` はムーヴ可能です。
ちなみに、`std:vector<char>` は Copyable かつ Movable なので、`V` はデフォルトでムーヴ可能です。
`std::move` については後で説明します。

ムーヴを使うために、rvalue reference の理解が必要なので、ここで簡単に説明しておきます。
従来の参照型は `T&` という形だけでしたが、C++11 で `T&&` という新たな形が追加されました。
`T&` を lvalue reference、`T&&` を rvalue reference と呼びます。
詳しくは [ここ](https://en.cppreference.com/w/cpp/language/reference) を見てください。
lvalue とか rvalue というのは、expression (式) の分類です。
全ての expression は lvalue, prvalue, xvalue のいずれかひとつに分類されます。
l は left、r は right の略、prvalue は pure rvalue の略、xvalue は expiring value の略です。
lvalue と xvalue をまとめて glvalue、prvalue と xvalue をまとめて rvalue と呼びます。
ものすごく大雑把に分類すると、名前がついてるのが lvalue で名前がついてないのが rvalue です。
例を挙げると、lvalue は変数や、関数などで、アドレスを取れます。
rvalue は即値、関数呼び出し(の返り値)などで、アドレスを取れません。
詳しくは [ここ](https://en.cppreference.com/w/cpp/language/value_category) を見てください。

例外はありますが、大雑把に言うと lvalue reference `T&` は lvalue を受けることができ、
rvalue reference `T&&` は rvalue を受けることができます。
lvalue reference は関数の引数や返り値で使うだけでなく、参照型変数としても使います。
rvalue reference は専ら関数の引数や返り値で使うことが多いです。

何故こんなややこしいルールを導入したのでしょうか。
それは、ムーヴ操作とコピー操作を区別しながらも同様のインターフェースで記述したかったからだと思います。
ムーヴ可能 (Movable) であるときは、ムーヴコンストラクタとムーヴ代入演算子が定義されていて、それらの挙動はムーヴであることが期待されています。
以下のようなクラス  `M` が自分で作る典型的な Movable class です。

```c++
struct M  // Movable class example
{
    // Default constructor
    M() = default;
    // Move constructor
    M(M&& rhs) noexcept : M() { swap(rhs); }
    // Move assign operator
    M& operator=(M&& rhs) noexcept { swap(rhs); return *this; }
    void swap(M& rhs) noexcept {
        // *this と rhs の中身を入れ変える。
    }
    C(const C&) = delete;
    C& operator=(const C&) = delete;
};
```
`swap()` というメンバ関数は、通常全てのメンバ変数の中身を入れ替えるという操作を指します。基本的な型については、`std::swap()` という関数が `#include <utility>` に用意されています。
`move` された後のオブジェクトは不定であり再初期化なしには使ってはいけないこととする設計も可能ですが、「空」の状態のオブジェクトと `swap` するという設計にしておいた方が無難だと私は思います。
`M` では、コピーコンストラクタとコピー代入演算子が `delete` されていますが、これらを実装すれば、Copyable かつ Movable というクラスも作れます。
ムーヴ操作を、コピーと同じ挙動として実装しても意味としてはまず問題はありませんが、一般に、ムーヴ操作は、コピー操作よりも低コスト、高速であることが期待されます。
C++11 以降の STL コンテナは必ずしも Copyable な class でなくても Movable な class であればそれを要素として典型的な使い方が出来るようになっています。

Movable class は Copyable class と出来るだけ同じような使い方ができて、しかしオーバーロードによってコンパイラが挙動を区別できるため、
コンパイル時にそれぞれのコードでコピーかムーヴどちらの操作を実行するか決まります。

```c++
void f(M&& m)
{
    M m1 = std::move(m);  // move constructor が呼ばれる
}

M create()
{
    M m;
    // ...
    return m;
}

struct A
{
    M m;
    const M& ref() const { return m; }  // const lvalue refernece を返す
    M&& ref() { return std::move(m); }  // rvalue reference を返す
    // M& ref() { return std::move(m); }  // M& を返すものと M&& を返すものはオーバーロードできない
}

int main()
{
    M m0;
    // M m1 = m0;  // copy constructor は定義されていないのでコンパイルエラー
    M m1 = std::move(m0);  // move constructor が呼ばれる
    M m2 = create(); // move constructor が呼ばれる
    m2 = std::move(m1);  // move assign operator が呼ばれる
    M&& m3 = std::move(m2);  // rvalue reference で xvalue を受ける
    f(std::move(m3));  // m3 は lvalue なので std::move() で xvalue にする必要がある
    A a0;
    M m4 = a0.ref();  // non-const 版、move constructor が呼ばれる
    M&& m5 = a0.ref();  // non-const 版が呼ばれる
    const M& m6 = a0.ref();  // non-const 版が呼ばれる
    const M& m7 = static_cast<const A&>(a0).ref();  // const 版が呼ばれる
    // M& m8 = a0.ref();  // rvalue は M& では受けられないのでコンパイルエラー
    const A a1;
    // M m7 = a1.ref();  // const 版、copy constructor を呼ぼうとするが、後者がないのでコンパイルエラー
    const M& m8 = a1.ref();  // const 版が呼ばれる
}
```

`std::move()` はただのキャストですが、lvalue を xvalue に変換するという点で意味を持ち、オーバーロードされた別の関数を選択させます。
具体的には lvalue の場合は `const T&` が、 rvalue の場合は `T&&` で受ける実体が選ばれます。
コンパイラが適切なオーバーロード関数を選択するために lvalue と rvalue(xvalue + prvalue) の区別はあると言って良いでしょう。
考えられる全ての組み合わせを挙げたわけではありませんが、我々が Movable class を使う場合は「移動」をしたいのであって、通常はごく一部の組み合わせでしか使いません。

上に挙げた例を見ると、オーバーロードで複数の参照型と const が使われている場合に、不可解な挙動をするようにも見えます。
const でない変数 `a0` において `ref()` を呼び出す場合、`const M&` で受けようとしても `A&&` を返す non-const 版が優先されてしまいます。
const 版を呼ぶには `static_cast<const A&>` を使う必要があります。
この例では敢えてオーバーロードさせてありますが、rvalue reference を返す関数を定義するときは、lvalue reference を返す関数とオーバーロードさせるのはやめて関数名を分けるのが懸命でしょう。

ムーヴコンストラクタ、ムーブ代入演算子、`swap()` は noexcept で実装しておくのが良いです。
`std::vector` などはメモリの再確保時に強い例外安全性を保証するために `std::move()` ではなく `std::move_if_noexcept()` を使います。
このとき、コピーコンストラクタと noexcept がついていないムーヴコンストラクタの両方が使える要素型においては、期待と異なりコピーコンストラクタが呼ばれてしまうからです。


### 参照の使い分け

関数の仮引数を参照型にする場合、`const T&`、`T&`、`T&&` のうちどれで受けるか迷うかも知れません。
そのようなときは以下のように使い分けると良いでしょう:

1. 関数内で対象オブジェクトを変更しない場合は `const T&` で受ける
2. 関数内で対象オブジェクトを変更して、後で呼び出し側がそれを使う場合は `T&` で受ける
3. 関数内で対象オブジェクトをムーヴして、後で呼び出し側がそれを使わない場合は `T&&` で受ける

`const T&&` も存在していますがまず使うことはないでしょう。
一時オブジェクトなどの rvalue は `const T&` または `T&&` で受けられるからです。
`const T&&` は込み入った用途で使うことがあるようですが、それは、どの種類の引数をどの種類の参照が受けられるか、オーバーロードでどのシグネチャが優先されるか、などを熟知した人がとても特殊な用途で使うものでしょうから、我々が気にする必要はありません。


