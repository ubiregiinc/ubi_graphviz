# UbiGraphviz
* このgemはなんらかのデータ構造を画像に出力します
  * dotコマンドを使います

## 対応しているモデル
* Account

## Requires
dot / graphviz

`brew install graphviz`

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ubi_graphviz', github: 'jiikko/ubi_graphviz'
```

And then execute:

    $ bundle

## Usage
```ruby
account = FactoryBot.create(:blank_account, login: :parent)
ubi_graphviz = UbiGraphviz::AccountModel.new(account, inspector: :id, filename: 'test')
ubi_graphviz.write # test.dot というファイルに出力する
ubi_graphviz.render # dotコマンドが使ってtest.pngという画像を出力する
```

### 出力例
* `account1 => account2` という関係の場合、`acocunt1`のparentが`acocnut2`となる
* 網掛けになっている要素は引数で渡したアカウントを指している

![img](https://github.com/jiikko/ubi_graphviz/blob/img/images/2parent_3sou.png "img")

![img](https://github.com/jiikko/ubi_graphviz/blob/img/images/all_mutal_lini_4sou.png "img")　　

![img](https://github.com/jiikko/ubi_graphviz/blob/img/images/simple_3sou.png "img")　　

![img](https://github.com/jiikko/ubi_graphviz/blob/img/images/simple_mutal_link.png "img")　　

![img](https://github.com/jiikko/ubi_graphviz/blob/img/images/yoko_2sou.png "img")

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
