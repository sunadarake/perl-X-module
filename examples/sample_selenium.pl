use v5.40;

# モジュールの場所を指定
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../local/lib/perl5";    # スクリプトからの相対パスを指定
    use lib "$FindBin::Bin/../lib";                # スクリプトからの相対パスを指定
}

use utf8::all;
use X;

# メイン処理
sub main() {
    say "スクレイピングを開始します...";

    # ヘッドレスモードでSeleniumドライバーを初期化
    my $selenium = X::Selenium->create_driver( 1, [ 1800, 1300 ] );

    try {
        # example.comにアクセス
        say "https://example.com/ にアクセスします...";
        $selenium->goto_page('https://example.com/');

        # h1タグの取得
        my $h1_element = $selenium->find_element('h1');
        my $h1_text    = $selenium->get_text($h1_element);
        say "見出し(h1): $h1_text";

        # pタグの取得（複数ある可能性があるため）
        my $p_elements = $selenium->find_elements('p');
        say "段落(p): " . scalar(@$p_elements) . "個見つかりました";

        # 各段落のテキストを表示
        my $count = 1;
        foreach my $p_element (@$p_elements) {
            my $p_text = $selenium->get_text($p_element);
            say "段落 $count: $p_text";
            $count++;
        }

        say "スクレイピングが完了しました";
    }
    catch ($e) {
        say "エラーが発生しました: $e";
    }
}

# スクリプトの実行
main();
