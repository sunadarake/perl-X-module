
use v5.40;

package X::HTML;

use utf8::all;
use HTML::HTML5::Parser;
use XML::LibXML::QuerySelector;
use Exporter 'import';

our @EXPORT = qw/
  hp_create_document
  hp_find_element
  hp_find_elements
  hp_get_text
  hp_get_attr
  hp_get_outer_html
  hp_get_inner_html
  hp_remove_doc
  /;

our $document;
our $parser;

sub hp_create_document($html) {
    $parser   = HTML::HTML5::Parser->new;
    $document = $parser->parse_string( $html, { encoding => 'utf-8' } );
    return $document;
}

sub hp_find_element( $doc, $css_selector ) {
    return $doc->querySelector($css_selector);
}

sub hp_find_elements( $doc, $css_selector ) {
    return $doc->querySelectorAll($css_selector);
}

sub hp_get_text($doc) {
    return $doc->textContent();
}

sub hp_get_attr( $doc, $attr ) {
    return $doc->getAttribute($attr);
}

sub hp_get_outer_html($doc) {
    return $doc->toString;
}

sub hp_get_inner_html($doc) {
    return join '', map { $_->toString } $doc->childNodes;
}

sub hp_remove_doc($doc) {
    $doc->parentNode->removeChild($doc);
}

1;

=encoding utf8

=head1 名前

X::HTML - HTMLドキュメントを簡単に操作するためのモジュール

=head1 概説

このモジュールはHTML文書を解析し、CSSセレクタを用いて要素を検索・操作するための関数群を提供する。

HTML::HTML5::ParserとXML::LibXML::QuerySelectorを内部で使用し、これらの機能を簡単に利用できるようにラッパー関数を提供している。

=head1 関数

=head2 hp_create_document

HTMLテキストからドキュメントオブジェクトを生成する。

- 引数: ($html) - 解析するHTML文字列
- 戻り値: ドキュメントオブジェクト

=head2 hp_find_element

CSSセレクタに一致する最初の要素を返す。

- 引数: ($doc, $css_selector) - ドキュメントオブジェクトとCSSセレクタ文字列
- 戻り値: マッチした要素（見つからない場合はundef）

=head2 hp_find_elements

CSSセレクタに一致するすべての要素のリストを返す。

- 引数: ($doc, $css_selector) - ドキュメントオブジェクトとCSSセレクタ文字列
- 戻り値: マッチした要素のリスト（配列）

=head2 hp_get_text

要素内のテキストコンテンツを取得する。

- 引数: ($doc) - 要素オブジェクト
- 戻り値: テキスト文字列

=head2 hp_get_attr

要素の指定された属性の値を取得する。

- 引数: ($doc, $attr) - 要素オブジェクトと属性名
- 戻り値: 属性値（属性が存在しない場合はundef）

=head2 hp_get_outer_html

要素自身を含むHTML文字列を取得する。

- 引数: ($doc) - 要素オブジェクト
- 戻り値: HTML文字列

=head2 hp_get_inner_html

要素内の子要素のHTML文字列を取得する。

- 引数: ($doc) - 要素オブジェクト
- 戻り値: HTML文字列

=head2 hp_remove_doc

要素をDOMツリーから削除する。

- 引数: ($doc) - 削除する要素オブジェクト
- 戻り値: なし

=head1 注意

内部的にはHTML::HTML5::ParserとXML::LibXML::QuerySelectorを使用しているため、これらのモジュールに依存する。

モジュール内でutf8::allを使用しているため、Unicode文字の処理が適切に行われる。

=cut
