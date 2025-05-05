
use v5.40;

package X::Log;

use utf8::all;

use Log::Log4perl;
use File::Path qw(make_path);
use POSIX      qw(strftime);
use Path::Tiny;
use File::Basename;
use File::Spec;
use Cwd qw(abs_path);
use Exporter 'import';
use Carp 'croak';

our @EXPORT = qw(
  init_logger
  log_info
  log_warn
  log_error
  log_debug
  log_success
);

# ロガーインスタンス（モジュール内部で使う）
my $_logger;

# --- ロガーの初期化 ---
# ログルートディレクトリ（例: /var/log/myapp）を引数として渡す
sub init_logger ($log_root_dir) {

    # 既に設定済みなので終わり。
    return if $_logger;

    croak "log_root_dirが設定されていません。" unless $log_root_dir;

    # 現在の日時を "YYYYMMDD_HHMMSS" 形式で取得
    my $datetime = strftime( '%Y%m%d_%H%M%S', localtime );

    # ログ出力先のディレクトリパスを生成
    my $log_dir = path( $log_root_dir, $datetime );

    # ディレクトリが存在しなければ作成
    make_path($log_dir) unless -d $log_dir;

    # ログレベルと Log4perl レベルのマッピング
    my %levels = (
        info    => 'INFO',
        error   => 'ERROR',
        warn    => 'WARN',
        success => 'INFO',    # success は info と同じ扱い
        debug   => 'DEBUG',
    );

    # ログ設定を構築するアペンダーリスト
    my @appenders;

    # --- 標準出力（カラー付き）の設定 ---
    push @appenders, qq{
        log4perl.appender.Screen=Log::Log4perl::Appender::ScreenColoredLevels
        log4perl.appender.Screen.stderr=0
        log4perl.appender.Screen.layout=Log::Log4perl::Layout::PatternLayout
        log4perl.appender.Screen.layout.ConversionPattern=%d %p [%M %F:%L] %m%n
        log4perl.appender.Screen.encoding=UTF-8
        log4perl.appender.Screen.color.TRACE=blue
        log4perl.appender.Screen.color.DEBUG=CYAN
        log4perl.appender.Screen.color.INFO=green
        log4perl.appender.Screen.color.WARN=yellow
        log4perl.appender.Screen.color.ERROR=red
        log4perl.appender.Screen.color.FATAL=red
    };

    # --- ファイル出力の設定 ---
    for my $key ( keys %levels ) {
        my $level = $levels{$key};
        my $file  = $log_dir->child("${key}_${datetime}.log");

        push @appenders, qq{
            log4perl.appender.$key=Log::Log4perl::Appender::File
            log4perl.appender.$key.filename=$file
            log4perl.appender.$key.mode=append
            log4perl.appender.$key.layout=Log::Log4perl::Layout::PatternLayout
            log4perl.appender.$key.layout.ConversionPattern=%d %p [%M %F:%L] %m%n
            log4perl.appender.$key.Threshold=$level
            log4perl.appender.$key.utf8=1
        };
    }

    # 全アペンダーをまとめてルートロガーに設定
    my $conf = join "\n", @appenders,
      ( "log4perl.rootLogger=DEBUG, Screen, " . join( ", ", keys %levels ) );

    # 設定を適用してロガーを初期化
    Log::Log4perl::init( \$conf );
    $_logger = Log::Log4perl->get_logger;
}

# --- ロガーが初期化されているか確認 ---
sub _ensure_logger { init_logger() unless $_logger; }

# --- ログ出力関数群（日本語名付き） ---
sub log_info {
    _ensure_logger();
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $_logger->info( join( "\n", @_ ) );
}

sub log_error {
    _ensure_logger();
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $_logger->error( join( "\n", @_ ) );
}

sub log_warn {
    _ensure_logger();
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $_logger->warn( join( "\n", @_ ) );
}

sub log_debug {
    _ensure_logger();
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $_logger->debug( join( "\n", @_ ) );
}

sub log_success {
    _ensure_logger();
    local $Log::Log4perl::caller_depth = $Log::Log4perl::caller_depth + 1;
    $_logger->info( "[SUCCESS] " . join( "", join( "\n", @_ ) ) );
}

1;

=encoding utf8

=head1 名前

Util::Logging - ログ出力を簡単に管理するためのユーティリティモジュール

=head1 概略

    use Util::Logging qw(init_logger log_info log_error);
    
    # ロガーの初期化
    init_logger('/var/log/myapp');
    
    # 各種ログの出力
    log_info('処理を開始しました');
    log_error('エラーが発生しました: %s', $error_message);

=head1 説明

このモジュールは、アプリケーションでのログ出力を簡単に管理するためのインターフェースを提供する。Log::Log4perlをベースにし、標準出力（カラー付き）と複数のログファイル（レベル別）への出力を自動的に設定する。

ログは日時ごとにディレクトリ分けされ、ログレベル別に異なるファイルに書き出される。これにより、特定のレベルのログだけを確認したい場合に便利である。

=head1 関数

=head2 init_logger

ロガーを初期化する。この関数は他のログ関数を呼び出す前に必ず実行する必要がある。

- 引数: ($log_root_dir)
- 戻り値: なし
- 例外: ディレクトリが作成できない場合など

ログのルートディレクトリを指定すると、その下に現在日時のフォーマット（YYYYMMDD_HHMMSS）でサブディレクトリを作成し、ログファイルを格納する。

=head2 log_info

情報レベルのログを出力する。

- 引数: (@messages)
- 戻り値: なし
- 例外: ロガーが初期化されていない場合

=head2 log_error

エラーレベルのログを出力する。

- 引数: (@messages)
- 戻り値: なし
- 例外: ロガーが初期化されていない場合

=head2 log_warn

警告レベルのログを出力する。

- 引数: (@messages)
- 戻り値: なし
- 例外: ロガーが初期化されていない場合

=head2 log_debug

デバッグレベルのログを出力する。

- 引数: (@messages)
- 戻り値: なし
- 例外: ロガーが初期化されていない場合

=head2 log_success

成功メッセージをログ出力する。内部的にはINFOレベルとして処理され、"[SUCCESS]"というプレフィックスが付与される。

- 引数: (@messages)
- 戻り値: なし
- 例外: ロガーが初期化されていない場合

=head1 内部関数

=head2 _ensure_logger

ロガーが初期化されているかを確認する内部関数。初期化されていない場合は例外を発生させる。

- 引数: なし
- 戻り値: なし
- 例外: ロガーが初期化されていない場合

=cut
