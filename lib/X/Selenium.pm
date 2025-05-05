
use v5.40;

package X::Selenium {

    use utf8::all;
    use Moo;
    use Selenium::Remote::Driver;
    use Selenium::Chrome;
    use JSON;
    use X::Sleep;
    use List::Util qw(shuffle);

    # 一般的なUser-Agentリスト
    my @user_agents = (

        # デスクトップブラウザ
'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36',
'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.2 Safari/605.1.15',
'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:90.0) Gecko/20100101 Firefox/90.0',
'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.107 Safari/537.36',

        # モバイルブラウザ
'Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
        'Mozilla/5.0 (Android 11; Mobile; rv:88.0) Gecko/88.0 Firefox/88.0',
'Mozilla/5.0 (Linux; Android 11; SM-G998B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36',
'Mozilla/5.0 (iPad; CPU OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
'Mozilla/5.0 (Linux; Android 10; SM-A205U) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36'
    );

    # ランダムなUser-Agentを取得する関数
    sub _get_random_user_agent() {
        my @shuffled = shuffle(@user_agents);
        return $shuffled[0];
    }

    has 'driver' => (
        is => 'lazy',

    );

    sub create_driver( $class, $is_headless = 1, $window_size = [ 1800, 1300 ] )
    {
        say "Seleniumドライバーを初期化中...";

        # Chromeドライバーを設定
        my $driver;

        my ( $wnd_w, $wnd_h ) = @$window_size;

        my $ua = _get_random_user_agent();

        try {

            my $args = [

                # ヘッドレスモード関連設定

                "no-sandbox",                   # サンドボックス無効化
                "disable-gpu",                  # GPUアクセラレーション無効化
                "disable-dev-shm-usage",        # /dev/shm使用無効化
                "disable-application-cache",    # アプリケーションキャッシュ無効化
                "ignore-certificate-errors",    # 証明書エラー無視
                    #                             # ウィンドウサイズ設定（縦に長く設定）
                "window-size=$wnd_w,$wnd_h",
                "user-agent=$ua",
            ];

            if ($is_headless) {
                unshift @$args, "headless=new";
            }

            # Chrome オプション設定
            my $extra_capabilities = {
                'goog:chromeOptions' => {
                    'args' => $args,

                    # 'prefs' => {
                    #     'profile.default_content_settings.popups' => 0,
                    # }
                }
            };

            $driver = Selenium::Chrome->new(

                # binary_port => 4444,
                extra_capabilities => $extra_capabilities,
            );

            # 暗黙的待機時間を設定（要素が見つからない場合に最大10秒待機）
            # $driver->set_implicit_wait_timeout(3000);

            say "Seleniumドライバーの初期化に成功しました";
        }
        catch ($e) {
            die "Seleniumドライバーの初期化に失敗しました: $e";
        }

        return $class->new( driver => $driver );

    }

    sub goto_page( $self, $url ) {
        $self->driver->get($url);
    }

    sub get_current_source($self) {
        $self->driver->get_page_source();
    }

    sub find_element( $self, $css_selector ) {
        return $self->driver->find_element( $css_selector, 'css' );
    }

    sub find_elements( $self, $css_selector ) {
        return $self->driver->find_elements( $css_selector, 'css' );
    }

    sub get_attribute( $self, $element, $attribute ) {
        return $element->get_attribute($attribute);
    }

    sub get_text( $self, $element ) {
        return $element->get_text();
    }

    sub get_current_tab($self) {
        return $self->driver->get_current_window_handle();
    }

    sub switch_to_tab( $self, $tab_handle ) {
        $self->driver->switch_to_window($tab_handle);
    }

    sub create_new_tab($self) {
        $self->driver->execute_script("window.open('about:blank', '_blank');");
        my $handles       = $self->driver->get_window_handles();
        my $new_handle_id = $handles->[-1];

        # 新しく開いたタブに切り替える（通常は配列の最後の要素）
        $self->driver->switch_to_window($new_handle_id);

        return $new_handle_id;
    }

    # クリーンアップ処理
    sub DEMOLISH ( $self, $in_global_destruction ) {
        if ( $self->{driver} ) {
            say "Seleniumドライバーを終了します";
            $self->driver->quit();
        }
    }
}

1;

=pod

=encoding utf8

=head1 名称

X::Selenium - Selenium WebDriverを使った自動ブラウザ操作のためのPerlモジュール

=head1 概説

このモジュールはSelenium WebDriverを使用してブラウザの自動操作を行うための機能を提供する。ランダムなUser-Agentの選択やヘッドレスモードの設定、ページ移動や要素の操作など、Webスクレイピングや自動テストに必要な基本機能を実装している。

=head1 メソッド

=head2 _get_random_user_agent

内部関数として、ランダムなユーザーエージェント文字列を返却する。

- 入力: なし
- 戻り値: String - ランダムに選択されたユーザーエージェント文字列

=head2 create_driver

Seleniumドライバーを初期化し、X::Seleniumオブジェクトを生成する。

- 入力:
  - $class: String - クラス名
  - $is_headless: Boolean - ヘッドレスモードで実行するかどうか（デフォルト：1）
  - $window_size: ArrayRef - ウィンドウサイズ [幅, 高さ]（デフォルト：[1800, 1300]）
- 戻り値: X::Selenium - 初期化されたSeleniumオブジェクト

=head2 goto_page

指定されたURLにブラウザを移動させる。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $url: String - 移動先のURL
- 戻り値: なし

=head2 get_current_source

現在表示されているページのソースコードを取得する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
- 戻り値: String - 現在のページのHTML

=head2 find_element

CSSセレクタを使用して単一の要素を検索する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $css_selector: String - CSSセレクタ
- 戻り値: Selenium::Remote::WebElement - 見つかった要素

=head2 find_elements

CSSセレクタを使用して複数の要素を検索する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $css_selector: String - CSSセレクタ
- 戻り値: ArrayRef[Selenium::Remote::WebElement] - 見つかった要素の配列

=head2 get_attribute

要素の指定された属性値を取得する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $element: Selenium::Remote::WebElement - 対象の要素
  - $attribute: String - 取得する属性名
- 戻り値: String - 属性値

=head2 get_text

要素のテキスト内容を取得する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $element: Selenium::Remote::WebElement - 対象の要素
- 戻り値: String - 要素のテキスト内容

=head2 get_current_tab

現在アクティブなタブのハンドルを取得する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
- 戻り値: String - 現在のタブハンドル

=head2 switch_to_tab

指定されたタブハンドルに切り替える。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $tab_handle: String - 切り替え先のタブハンドル
- 戻り値: なし

=head2 create_new_tab

新しいタブを作成し、そのタブに切り替える。

- 入力:
  - $self: X::Selenium - オブジェクト自身
- 戻り値: String - 新しく作成されたタブのハンドルID

=head2 DEMOLISH

オブジェクトが破棄される際に自動的に呼び出され、Seleniumドライバーを終了する。

- 入力:
  - $self: X::Selenium - オブジェクト自身
  - $in_global_destruction: Boolean - グローバル破壊中かどうか
- 戻り値: なし

=head1 属性

=head2 driver

Selenium::Remote::Driverオブジェクトを保持する。

- 型: Selenium::Remote::Driver
- 初期化: 遅延評価 (lazy)

=cut
