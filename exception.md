## 例外

C 言語にはない例外について、要点を説明します。
特に、例外とデストラクタの関係について分かってもらえるとうれしいです。


### 例外の概要

C++ の例外は、大域脱出の手段です。
例外オブジェクトを作成し、`throw` 文で投げます。
`try` 節の中で投げられた例外オブジェクトは呼び出し側を辿ってスタックを巻き戻し、最初に `catch` 節(例外ハンドラ)が定義されているところまで処理を飛ばします。
ただし、`throw` 文を投げる時点で生きていたスタックオブジェクトで、例外ハンドラに到達するまでの間にスコープを抜けて寿命を終えたものを対象としたデストラクタの呼び出しだけは必ず実行されます。

```c++
int main()
{
    try {
        A a;
        // ...
        throw std::runtime_error("error message");
        // ...
    } catch (std::exception& e) {
        ::printf("error %s\n", e.what());
    }
}
```
この例では `catch` 節の実行前に `a` の寿命が終わってデストラクタが呼ばれます。

スレッドの一番上の呼び出し側コード(メインスレッドの場合は main 関数)に至っても例外ハンドラが定義されていない、すなわちその例外を投げたコードがどの `try` 節にも含まれていなかった場合、プログラムは強制終了します。
マルチスレッドプログラムの場合、ひとつのスレッドで例外をキャッチしそびれるとプロセスまるごと死にます。
STL も例外を飛ばす可能性がありますから、例外は常に飛ぶ可能性があると考えて、コードを書くようにしましょう。
つまり、一番上の呼び出しコード (main 関数やスレッドの起動時に実行する関数) で例外ハンドラを定義するのを忘れないようにしましょう。
STL で投げられる例外や、お行儀の良い大抵の例外型は `std::exception` を継承していますので、それで受ければほぼ全ての例外がキャッチできます。
例外を飛ばさないのは、C 言語互換の関数と、`noexcept` 指定で例外を飛ばさないことが明示されている関数だけで、それ以外は全部飛ばす可能性があるものとして扱いましょう。
ただし、デストラクタは何も指定しなくてもデフォルトで `noexcept` 扱いとなります。

C++ 例外の問題点として、その実現にはコストがかかります。
バイナリサイズが増えるし、遅いです。
その原因は大域脱出の仕組みだったり、途中経路のデストラクタ呼び出しのための処理だったりするようです。


例外がどこで発生したのかを知る方法は標準では用意されていません。
自分で問題を解析するために必要な情報を例外オブジェクトに付加する必要があります。
たとえばデバッグが目的ならスタックトレース情報などが欲しくなるでしょう。
標準ライブラリではありませんが、例えば、[cybozulib](https://github.com/herumi/cybozulib/) の `cybozu::Exception` はコンストラクタでスタックトレースを取ってオブジェクト内に保持し、例外ハンドラでそれを参照できる機能を持っています。


### デストラクタ内で発生した例外処理

例外を投げている途中に例外が投げられたらどうなるでしょうか？そのようなことが起こり得るのは、オブジェクトのデストラクタ内の処理です。
例外が投げられても、スコープを抜けたオブジェクトのデストラクタは必ず実行されるのでした。
例外が飛んでいる最中のデストラクタ処理で、デストラクタの外に新たな例外が投げられることが分かったときにプログラムは強制終了されます。
逆に言えば、デストラクタ内で例外が発生しても、例外ハンドラをデストラクタ内に定義しておいて、例外処理すれば、プログラムは続行できます。

このような理由から、デストラクタ実行中に発生した例外の処理はほぼ握り潰さざるを得ませんが、それをどう扱うかはプログラム設計における選択になります。
以下に例を挙げますが、敢えてログを吐くか(`~A()`)、潔くプロセスを自分で殺すか(`~B()`)、無言で握り潰すか(`~C()`)、などの選択肢があります。
握り潰すとは例外をキャッチしておいて何もしないことです。


```c++
~A() {
    try {
        // try to deallocate resources...
    } catch (std::exception& e) {
        try {
            // try to put logs.
        } catch (...) {
            // do nothing
        }
    }
}

~B() {
    try {
        // try to deallocate resources...
    } catch (...) {
        ::exit(1);
    }
}

~C() {
    try {
        // try to deallocate resources...
    } catch (...) {
        // do nothing
    }
}
```

### 例外と返り値などの使い分け

例外は便利ですが、重たいというデメリットもあるため、使いどころには注意した方が良いでしょう。
発生頻度が高く、例外処理が性能に影響を及ぼし得るエラーについては、例外を使わずに返り値や参照引数経由でエラー情報を呼び出し側に伝え、条件分岐を用いてエラー処理を行う方が良いでしょう。

C++ でプログラムを書き、STL のコンテナなどを使う時点で、`std::bad_alloc()` が投げられる可能性は常にあります。
C++ で書かれたコードは RAII の影響もあって、至るところで暗黙にメモリアロケートされる傾向にあります。
例外ハンドラも例外ではありません。例外ハンドラ内で `std::bad_alloc()` が投げられたら適切に処理してプログラムを動かし続けることは困難だと思います。
そういう意味では、C++ は C よりもメモリにシビアな環境で動かすのは難しいのかも知れません。
そのような環境を前提に C++ でプログラムを開発する場合は、例外や STL 等を使わないなどの特殊な使い方をする場合があるかも知れませんが、本書で対象としている C++ の便利さを享受できなくなるのが辛いところです。


### 例外仕様

C++ の関数には、例外の種類を列挙させ、それ以外は投げられないことを示すインターフェースがあり、例外仕様と呼ばれていたそうです。
具体的には `void f() throw(std::runtime_error);` といったものです。
しかし、C++11 で例外仕様は非推奨になり、C++17 では削除されました。
どうやら多くのコンパイラがこれを真面目に実装せず、単に無視するだけだったようです。
代わりに C++11 では `noexcept` キーワードが導入されました。
これは、例外が投げられるのを許可するかしないかだけを指定する、より単純なものです。
`noexcept` を指定した場合は例外が投げられるのを許可せず、実際に投げられたら、呼出側に例外ハンドラが定義されていたとしても、即座にプログラムは強制終了されます。
`noexcept` を指定しない場合は、例外は投げられ得るものと見做されます。
この情報は例外処理の最適化などに使われるようです。

デフォルトのデストラクタが `noexcept` かどうかは[ここ](https://en.cppreference.com/w/cpp/language/destructor)に書いてあるように、条件によって決まるようですが、通常は `noexcept` であると思って良いです。
また、`virtual` にする場合などを除いて、空のデストラクタを自分で定義するのは良くありません。
`std::is_trivially_destructible<T>` が `false` になってしまい、オブジェクト再利用時などの最適化が効かなくなるからです。

C++17 以降 `noexcept` 指定が関数の型情報に含まれるようになったので、関数ポインタを扱うときはその型に注意しましょう。
`noexcept` の有無のみ異なるオーバーロードは許されないようですが、`noexcept` 指定した関数ポインタに `noexcept` でない関数は代入できなくなるようです。
