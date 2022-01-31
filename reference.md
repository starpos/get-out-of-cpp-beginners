## 参照

改めて説明しますが、ポインタ(ポインタ型変数)とは、オブジェクトのメモリ上の位置、すなわちアドレスをデータとして格納する変数です。
ポインタは C 言語でも使いますし、解説もたくさんありますので、これ以上はここで説明しません。

参照は、プログラミングをする上で実質的にポインタに似た性質を持つものであると見なして構いません。
C++ に慣れた人はポインタよりも参照を多用します。
これからの説明で、C++ で参照がここまで重要な位置を占めるようになった理由が分かってもらえるとうれしいです。


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
逆に`nullptr` が絶対に返らないなら、ポインタではなく参照を返すインターフェースにすべきです。
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
void f_cref(const C& c)
{
    // c を read-only アクセスする
}

void f_ref(C& c)
{
    // c を操作する
}

void f_value(C c)
{
    // c はコピーされており、呼び出し側のコピー元には影響を与えない
}

struct A
{
    C c;
    const C& cref() const { return c; }
    C& ref() { return c; }
    // C get() const { return c; }
};

int main()
{
    C c0;
    C c1 = c0;  // copy constructor が呼ばれる
    C c2;
    c2 = c1;  // copy assign operator が呼ばれる
    f_cref(c0);  // c0 は変更されない
    f_ref(c1);  // c0 は変更される(と考えられる)
    f_value(c0);  // copy constructor が呼ばれ、c0 は変更されない

    A a;
    const C& c3 = a.cref(); // コピーは起こらない
    C& c4 = a.ref(); // コピーは起こらない
    C c5 = a.cref();  // copy constructor が呼ばれる
    c5 = a.cref();  // copy assign operator が呼ばれる
    C c6 = a.ref();  // copy constructor が呼ばれる
    c6 = a.ref();  // copy assign operator が呼ばれる
}
```

`f_cref()` や `f_ref()` のように参照渡しすることは Copyable に限らず可能ですが、
`f_value()` はコピー操作を必要とするので、Copyable でないと使えません。
`A::cref()` や `A::ref()` は参照を返しますので、
参照型変数 (`c3`, `c4`) で受ければ同じオブジェクトを指すことになりますが、
値型変数 (`c5`, `c6`) で受ければ、コピーが発生します。
値返しをする `A::get()` は `C` が Copyable であれば定義できますが、ここでは使っていませんし、オススメしません。
`A::get()` を使ってこの例のような操作をしてみれば理由の一端は分かりますが、
詳しくは説明しません(というかできません)。
`A::cref()` で困ることはありませんので、そちらを使うようにし、
メンバ変数を値返しするのはやめましょう。


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
    M(const M&) = delete;
    M& operator=(const M&) = delete;
};
```

`swap()` というメンバ関数は、通常全てのメンバ変数の中身を入れ替えるという操作を指します。基本的な型については、`std::swap()` という関数が `#include <utility>` に用意されています。
元々の考え方では、`move` された後のオブジェクトは再初期化なしには使ってはいけないこととなっていますが、自分でムーヴ可能な型を設計する場合は「空」の状態のオブジェクトと `swap` するという設計にしておいた方が無難だと私は思います。
もちろん自分が設計していない型に対して `swap` 挙動を期待してはいけません。
例えば、`M(M&&) noexcept = default;` `M& operator=(M&&) noexcept = default;` などデフォルト定義を使うと `swap` の挙動にはなりません。
手元で試したところ基本型やポインタ型などのメンバ変数についてはコピー挙動となるようです。
つまり move 元の変数は破壊されるため、再初期化なしに使ってはいけない、という原則に従う必要があります。
たとえば `std::vector<T>` 型なら move 元変数を再利用する前に `clear()` を呼ぶなどの手当が必要となります。
まとめると move に求められる要件は swap とは異なりますが、swap で簡単に実装可能なので、そうしてしまった方が楽だし間違えにくいよというのが私の主張です。
ただ、性能を犠牲にするケースがあることは確かなので、この設計を選ぶかどうかは性能に与える影響次第だとも言えます。
C++20 の `std::movable` は `std::swappable` であることも求めているようなので、どちらにせよ `swap()` メンバ関数は必要になるのでしょう。
(swap 実装を自分でするとメンバ変数の swap し忘れというポカをやる可能性はあります。これを嫌だと思うなら move は default 実装にして、move を使って swap を典型的なコードで実装する方がいいという説もあり得ますね。。)

`M` では、コピーコンストラクタとコピー代入演算子が `delete` されていますが、これらを実装すれば、Copyable かつ Movable というクラスも作れます。
ムーヴ操作を、コピーと同じ挙動として実装しても意味としてはまず問題はありませんが、一般に、ムーヴ操作は、コピー操作よりも低コスト、高速であることが期待されます。
C++11 以降の STL コンテナは必ずしも Copyable な class でなくても Movable な class であればそれを要素として典型的な使い方が出来るようになっています。

Movable class は Copyable class と出来るだけ同じような使い方ができて、しかしオーバーロードによってコンパイラが挙動を区別できるため、
コンパイル時にそれぞれのコードでコピーかムーヴどちらの操作を実行するか決まります。

```c++
void f_rref(M&& m)
{
    M m1 = std::move(m);  // move constructor が呼ばれる
}

void f_lref(M& m)
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
    const M& cref() const { return m; }  // const lvalue refernece を返す
    M&& ref() { return std::move(m); }  // rvalue reference を返す
    // M& ref() { return std::move(m); }  // 返り値の型が違うだけではオーバーロードできない
    // M get() { return m; }  // M の copy constructor がないと定義できない
};

int main()
{
    M m0;
    // M m1 = m0;  // copy constructor は削除されているのでコンパイルエラー
    M m1 = std::move(m0);  // move constructor が呼ばれる
    M m2 = create(); // move constructor が呼ばれると思いきや copy elision によって直接構築される
    m2 = create(); // move assign operator が呼ばれる
    m2 = std::move(m1);  // move assign operator が呼ばれる
    M&& m3 = std::move(m2);  // rvalue reference で xvalue を受ける
    f_rref(std::move(m3));  // m3 は lvalue なので std::move() で xvalue にする必要がある
    f_lref(m3); // f_rref() と同じことが出来るが、move したことが分かりにくい
    A a0;
    M m4 = a0.ref();  // move constructor が呼ばれる
    // M m5 = a0.cref(); // copy constructor を呼ぼうとするがないのでコンパイルエラー
    // M&& m6 = a0.cref(); // const M& は M&& や M& で受けられないのでコンパイルエラー
    const M& m7 = a0.cref(); // move は起きない
    M&& m8 = a0.ref();  // move は起きない、a0.ref() と m8 は同じオブジェクトを指している
    M m9 = std::move(m8);  // a0.ref() が指しているオブジェクトが move される
    // M& m10 = a0.ref();  // rvalue は M& では受けられないのでコンパイルエラー
    const M& m11 = a0.ref();  // move は起きない
}
```

`std::move()` はただのキャストですが、lvalue を xvalue に変換するという点で意味を持ち、オーバーロードされた別の関数を選択させます。
具体的には lvalue を渡したら `const T&` または `T&` で受ける関数、
rvalue を渡したら `T&&` で受ける関数が選ばれます。
コンパイラが適切なオーバーロード関数を選択するために lvalue と rvalue(xvalue + prvalue) の区別はあると言って良いでしょう。
考えられる全ての組み合わせを挙げたわけではありませんが、我々が Movable class を使う場合は「移動」をしたいのであって、通常はごく一部の組み合わせでしか使いません。

`create()` は値を返します。これは prvalue です。
よって `m2` への代入は意味としてはムーヴになります。
しかし、別の章で説明した copy elision による最適化がはたらき、実際はムーヴが呼ばれないことがあります。
当たり前のことですが念を押しておくと、copy elision が義務化されたとはいえ、その有無で挙動が変わるような
コピーやムーヴの実装をすべきではありません。

直接構築された場合と、構築されてムーヴされた場合とでオブジェクトの中身が同じになることが期待されています。
copy elision の有無で結果が変わったら使う側は困ります。
もちろん、わざと挙動が異なるクラスを作ることは可能ですが、そんなことをしてうれしいケースはまずないと思います。

`f_rref()` と `f_lref()` は引数の渡し方にこそ違いがあれ、中身に区別はありません。
私は、意味の違いで使い分けることにしています。
渡した引数が move されることを前提とする場合は、`f_rref()` の方を使います。
渡した引数を関数呼び出し後に利用する、例えばデータを呼び出し側に渡すなどの場合、は、`f_lref()` を使います。
データが移動する向きが `f_rref()` と `f_lref()` で逆であることに注意してください。
この使い分けルールは、コードの可読性およびメンテナンス性にとってかなり重要だと思います。

ムーヴコンストラクタ、ムーブ代入演算子、`swap()` は `noexcept` で実装しておくのが良いです。
`std::vector` などはメモリの再確保時に強い例外安全性を保証するために `std::move()` ではなく `std::move_if_noexcept()` を使います。
このとき、コピーコンストラクタと `noexcept` がついていないムーヴコンストラクタの両方が使える要素型においては、期待と異なりコピーコンストラクタが呼ばれてしまうからです。
厳密には、ムーヴコンストラクタ(およびムーヴ代入演算子)は、
`std::is_move_constructible`
(`std::is_move_assignable`)
`std::is_nothrow_move_constructible`
(`std::is_nothrow_move_assignable`)
`std::is_trivially_move_constructible`
(`std::is_trivially_move_assignable`)
の 3 つの分類がなされていて、自分で実装する場合、可能であれば nothrow constructible/assignable なものにしておくのが良いということです。`swap` を用いて実装する場合は nothrow constructible/assignable にできると思います。
同様にコピーコンストラクタ(コピー代入演算子)にも、
`std::is_copy_constructible`
(`std::is_copy_assignable`)
`std::is_nothrow_copy_constructible`
(`std::is_nothrow_copy_assignable`)
`std::is_trivially_copy_constructible`
(`std::is_trivially_copy_assignable`)
の分類がありますが、メモリ確保を伴う場合など、nothrow にするのが無理なケースも多いと思います。


### 参照の使い分け

関数の仮引数を参照型にする場合、`const T&`、`T&`、`T&&` のうちどれで受けるか迷うかも知れません。
そのようなときは以下のように使い分けると良いでしょう:

1. 関数内で対象オブジェクトを変更しない場合は `const T&` で受ける
2. 関数内で対象オブジェクトを変更して、後で呼び出し側がそれを使う場合は `T&` で受ける
3. 関数内で対象オブジェクトをムーヴして、後で呼び出し側がそれを使わない場合は `T&&` で受ける

`const T&&` も存在していますがまず使うことはないでしょう。
一時オブジェクトなどの rvalue は `const T&` または `T&&` で受けられるからです。
`const T&&` は込み入った用途で使うことがあるようですが、それは、どの種類の引数をどの種類の参照が受けられるか、オーバーロードでどのシグネチャが優先されるか、などを熟知した人がとても特殊な用途で使うものでしょうから、我々が気にする必要はありません。
