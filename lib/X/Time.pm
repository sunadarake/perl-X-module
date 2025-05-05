use v5.40;

package X::Time {
    use utf8::all;
    use Moo;

    has start_time => (
        is  => 'rw',
        isa => sub { die "start_time must be defined" unless defined $_[0] },
    );

    # クラスメソッド: 計測開始
    sub start($class) {
        return $class->new( start_time => time );
    }

    # インスタンスメソッド: 計測終了
    sub finish($self) {

        my $end_time = time;
        my $elapsed  = $end_time - $self->start_time;

        my $hours   = int( $elapsed / 3600 );
        my $minutes = int( ( $elapsed % 3600 ) / 60 );
        my $seconds = $elapsed % 60;

        printf "%02d::%02d::%02d\n", $hours, $minutes, $seconds;
    }
}

1;

=encoding utf8

=head1 名前

X::Time - 時間計測を行うためのシンプルなPerlモジュール

=head1 概略

    use X::Time;
    
    my $timer = X::Time->start();
    # 何らかの処理
    $timer->finish(); # 経過時間を表示

=head1 説明

このモジュールは処理の実行時間を計測し、時間：分：秒の形式で表示するための
シンプルなタイマー機能を提供する。計測開始時にインスタンスを生成し、
計測終了時にインスタンスメソッドを呼び出すことで使用する。

=head1 メソッド

=head2 start

    my $timer = X::Time->start();

クラスメソッド。計測を開始し、X::Timeクラスのインスタンスを返却する。
内部的には現在のUNIXタイムスタンプをstart_time属性に保存する。

- 引数: なし
- 戻り値: X::Timeオブジェクト

=head2 finish

    $timer->finish();

インスタンスメソッド。計測を終了し、経過時間を時:分:秒の形式で標準出力に表示する。
内部的にはstart_timeと現在時刻の差分を計算し、適切な形式に変換して出力する。

- 引数: なし
- 戻り値: なし（標準出力に経過時間を表示）

=head1 属性

=head2 start_time

計測開始時刻をUNIXタイムスタンプ（秒）で保持する属性。
読み書き可能。この属性は必須であり、未定義値が設定された場合はエラーとなる。

=cut
