# UbiGraphviz
graphvizの静止画像を生成するにはdotを使います。

## Requires
dot / graphviz

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ubi_graphviz', github: 'jiikko/ubi_graphviz'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ubi_graphviz

## Usage
```ruby
account = FactoryBot.create(:blank_account, login: :parent)
ubi_graphviz = UbiGraphviz::AccountModel.new(account, inspector: :id, filename: 'test')
ubi_graphviz.write # test.dot というファイルに出力する
ubi_graphviz.render # dotコマンドが使ってtest.pngという画像を出力する
```

### 出力例
#### テストコードで記述している図
* 矢印は方向は、child => parent というの関係を表している
* 網掛けになっている要素は、引数で渡ってきたアカウントを指している

![img](./images/2parent_3sou.png "img")  

![img](./images/all_mutal_lini_4sou.png "img")　　

![img](./images/simple_3sou.png "img")　　

![img](./images/simple_mutal_link.png "img")　　

![img](./images/yoko_2sou.png "img")  

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
