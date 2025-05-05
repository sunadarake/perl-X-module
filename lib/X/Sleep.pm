
package X::Sleep {
    use v5.40;
    use utf8::all;

    use Exporter qw(import);
    our @EXPORT = qw(ss_sleep ss_sleep_random);

    use Time::HiRes qw(sleep);

    # 指定された秒数だけスリープする関数
    # @param $sec - スリープする秒数
    sub ss_sleep ($sec) {
        say "Sleeping .... $sec 秒";
        sleep($sec);
    }

    # 指定された範囲内でランダムな秒数だけスリープする関数
    # @param $from - 最小スリープ秒数
    # @param $to - 最大スリープ秒数
    sub ss_sleep_random ( $from, $to ) {
        my $sec = $from + rand( $to - $from );

        # 小数点第2位まで丸める
        $sec = sprintf( "%.2f", $sec );
        say "Sleeping .... $sec 秒";
        sleep($sec);
    }
}

1;

=encoding utf8

=head1 名前

X::Sleep - プログラムの実行を一時停止するためのユーティリティ関数群

=head1 説明

このモジュールはプログラムの実行を一時停止（スリープ）するための関数を提供する。
Time::HiResモジュールを使用することで、秒単位の小数点以下の精度でのスリープが可能。
固定時間のスリープと、指定した範囲内でランダムな時間のスリープという2種類の機能を実装している。

=head1 関数

=head2 ss_sleep

指定された秒数だけスリープする関数。

- パラメータ:
 - $sec: スリープする秒数
- 戻り値: なし

指定された秒数だけプログラムの実行を一時停止する。
実行前に「Sleeping .... X 秒」というメッセージが表示される。

=head2 ss_sleep_random

指定された範囲内でランダムな秒数だけスリープする関数。

- パラメータ:
 - $from: 最小スリープ秒数
 - $to: 最大スリープ秒数
- 戻り値: なし

$fromから$toの範囲内でランダムな秒数を生成し、その時間だけプログラムの実行を一時停止する。
スリープ時間は小数点第2位まで丸められる。
実行前に「Sleeping .... X 秒」というメッセージが表示される。

=cut
