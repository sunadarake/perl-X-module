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
    my $selenium = X::Selenium->create_driver( 0, [ 1800, 1300 ] );

    try {
        # example.comにアクセス
        say "https://example.com/ にアクセスします...";
        $selenium->goto_page('https://example.com/');

        my $main_tab = $selenium->get_current_tab();

        my $sub_tab = $selenium->create_new_tab();

        $selenium->switch_to_tab($sub_tab);

        sleep(2);

        say "スクレイピングが完了しました";
    }
    catch ($e) {
        say "エラーが発生しました: $e";
    }
}

# スクリプトの実行
main();
