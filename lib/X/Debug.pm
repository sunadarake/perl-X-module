use v5.40;
use utf8::all;

package X::Debug;

use Data::Dumper;
use JSON qw(encode_json);
use JSON;
use File::Basename qw(basename);
use Exporter 'import';

# エクスポート可能な関数のリスト
our @EXPORT = qw(dd_dump_to_file dd_json_encode dd_json_to_file dd_html_to_file);

# デフォルトのダンプファイル名
my $dump_file_default = './debug_output.txt';

# デフォルトのJSONファイル名
my $json_file_default = './debug_output.json';

# デフォルトのJHTMLファイル名
my $html_file_default = "./debug_output.html";

# データダンプをファイルに保存する
# @param $data 保存するデータ
# @param $file 出力ファイル名（省略時はデフォルト）
sub dd_dump_to_file($data, $file = undef) {
    $file //= $dump_file_default;

    open my $fh, '>', $file or die "Cannot open file '$file': $!";
    print $fh Dumper($data);
    close $fh or warn "Failed to close file '$file': $!";

    say "Dumped data to $file";
}

sub dd_html_to_file($html_content, $file = undef) {
    $file //= $html_file_default;

    open my $fh, '>', $file or die "Cannot open file '$file': $!";
    print $fh $html_content;
    close $fh or warn "Failed to close file '$file': $!";

    say "HTML data to $file";
}

# オブジェクトをJSON形式にエンコードする
# @param $object エンコードするオブジェクト
# @return JSON文字列
sub dd_json_encode($object) {
    return JSON->new->canonical->pretty->encode($object);
}


# データをJSON形式でファイルに保存する
# @param $data 保存するデータ
# @param $file 出力ファイル名（省略時はデフォルト）
sub dd_json_to_file($data, $file = undef) {
    $file //= $json_file_default;

    open my $fh, '>', $file or die "Cannot open file '$file': $!";
    print $fh dd_json_encode($data);
    close $fh or warn "Failed to close file '$file': $!";

    say "Dumped JSON to $file";
}

1;

=encoding utf8

=head1 名前

Util::Debug - デバッグ情報出力のためのユーティリティ関数群

=head1 説明

このモジュールはデバッグ情報を様々な形式でファイルに出力するための
関数を提供する。Data::Dumper形式、JSON形式、HTMLなど複数の出力形式に
対応しており、開発中のデータ構造検証に役立つ。

=head1 関数

=head2 dd_dump_to_file

データダンプをファイルに保存する関数。

- パラメータ:
 - $data: 保存するデータ
 - $file: 出力ファイル名（省略時はデフォルト './debug_output.txt'）
- 戻り値: なし

Data::Dumperを使用してデータ構造の内容をファイルに出力する。
複雑なデータ構造の中身を確認する際に便利。

=head2 dd_html_to_file

HTML内容をファイルに保存する関数。

- パラメータ:
 - $html_content: 保存するHTML内容
 - $file: 出力ファイル名（省略時はデフォルト './debug_output.html'）
- 戻り値: なし

HTML形式のデータをそのままファイルに出力する。
ウェブスクレイピング結果などのHTML構造を確認する際に便利。

=head2 dd_json_encode

オブジェクトをJSON形式にエンコードする関数。

- パラメータ:
 - $object: エンコードするオブジェクト
- 戻り値: JSON文字列

オブジェクトをJSON形式の文字列に変換する。
整形されたJSONを生成し、blessed（オブジェクト）も変換対象とする。

=head2 dd_json_to_file

データをJSON形式でファイルに保存する関数。

- パラメータ:
 - $data: 保存するデータ
 - $file: 出力ファイル名（省略時はデフォルト './debug_output.json'）
- 戻り値: なし

データ構造をJSON形式に変換してファイルに保存する。
Webサービスとの連携やデータの可視化に便利。

=cut