use v5.40;
use utf8::all;

package X::Selenium {

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

=encoding UTF-8

=head1 名前

X::Selenium - Selenium WebDriverを使用したウェブブラウザ操作の簡易ラッパー

=head1 概要

    use X::Selenium;
    
    # ヘッドレスモードでドライバーを初期化
    my $selenium = X::Selenium->create_driver(1, [1800, 1300]);
    
    # URLに移動
    $selenium->goto_page('https://example.com');
    
    # 要素を見つける
    my $element = $selenium->find_element('.some-class');
    
    # テキストを取得
    my $text = $selenium->get_text($element);
    
    # 新しいタブを作成
    my $new_tab = $selenium->create_new_tab();
    
    # タブを切り替え
    $selenium->switch_to_tab($new_tab);

=head1 説明

C<X::Selenium>はSelenium WebDriverのPerlインターフェースを簡易化するためのラッパークラスです。
このモジュールはSelenium::Remote::DriverとSelenium::Chromeを使用して、Webブラウザの自動操作を行います。
主な特徴として、ランダムなUser-Agentの設定、ヘッドレスモードのサポート、新しいタブの作成と管理などがあります。

=head1 メソッド

=head2 クラスメソッド

=head3 create_driver

    my $selenium = X::Selenium->create_driver($is_headless, $window_size);

Seleniumドライバーを初期化し、X::Seleniumオブジェクトを作成して返します。

パラメータ:

- C<$is_headless> - ヘッドレスモードを有効にするかどうかを指定するブール値 (デフォルト: 1)
- C<$window_size> - ウィンドウサイズを指定する配列リファレンス [幅, 高さ] (デフォルト: [1800, 1300])

戻り値:

- X::Seleniumオブジェクト

=head3 _get_random_user_agent

    my $user_agent = X::Selenium->_get_random_user_agent();

定義済みのUser-Agentリストからランダムに1つを選択して返します。
内部使用のためのメソッドです。

戻り値:

- ランダムに選択されたUser-Agent文字列

=head2 インスタンスメソッド

=head3 goto_page

    $selenium->goto_page($url);

指定したURLにブラウザを移動させます。

パラメータ:

- C<$url> - アクセスするURL

戻り値:

- なし

=head3 get_current_source

    my $source = $selenium->get_current_source();

現在のページのHTMLソースを取得して返します。

戻り値:

- ページのHTMLソース（文字列）

=head3 find_element

    my $element = $selenium->find_element($css_selector);

CSSセレクタを使用して単一の要素を見つけて返します。

パラメータ:

- C<$css_selector> - 要素を特定するためのCSSセレクタ

戻り値:

- Selenium::Remote::WebElement オブジェクト（要素が見つかった場合）
- 要素が見つからない場合は例外が発生

=head3 find_elements

    my $elements = $selenium->find_elements($css_selector);

CSSセレクタを使用して複数の要素を見つけて返します。

パラメータ:

- C<$css_selector> - 要素を特定するためのCSSセレクタ

戻り値:

- Selenium::Remote::WebElement オブジェクトの配列リファレンス
- 要素が見つからない場合は空の配列リファレンス

=head3 get_attribute

    my $value = $selenium->get_attribute($element, $attribute);

指定した要素の特定の属性値を取得します。

パラメータ:

- C<$element> - 属性を取得する要素オブジェクト
- C<$attribute> - 取得する属性の名前

戻り値:

- 属性の値（文字列）
- 属性が存在しない場合はundefined

=head3 get_text

    my $text = $selenium->get_text($element);

指定した要素のテキスト内容を取得します。

パラメータ:

- C<$element> - テキストを取得する要素オブジェクト

戻り値:

- 要素のテキスト内容（文字列）

=head3 get_current_tab

    my $tab_handle = $selenium->get_current_tab();

現在アクティブなタブのハンドル（識別子）を取得します。

戻り値:

- 現在のタブのハンドル（文字列）

=head3 switch_to_tab

    $selenium->switch_to_tab($tab_handle);

指定したハンドルのタブに切り替えます。

パラメータ:

- C<$tab_handle> - 切り替え先のタブハンドル

戻り値:

- なし

=head3 create_new_tab

    my $new_tab_handle = $selenium->create_new_tab();

新しいタブを作成し、そのタブに自動的に切り替えます。

戻り値:

- 新しいタブのハンドル（文字列）

=head1 属性

=head2 driver

Selenium::Remote::Driverのインスタンスを保持します。
通常は直接アクセスせず、提供されているメソッドを使用してください。

=head1 デストラクタ

=head2 DEMOLISH

オブジェクトが破棄される際に自動的に呼び出され、Seleniumドライバーを適切に終了します。

戻り値:

- なし

=head1 依存モジュール

- Moo
- Selenium::Remote::Driver
- Selenium::Chrome
- JSON
- X::Sleep
- List::Util

=head1 使用例

    use X::Selenium;
    
    # 通常モード（ヘッドレスではない）でドライバーを初期化
    my $selenium = X::Selenium->create_driver(0, [1920, 1080]);
    
    # Googleに移動
    $selenium->goto_page('https://www.google.com');
    
    # 検索ボックスを見つける
    my $search_box = $selenium->find_element('input[name="q"]');
    
    # 検索キーワードを入力し検索実行
    $search_box->send_keys('Perlプログラミング');
    $search_box->submit();
    
    # 検索結果を取得
    my $results = $selenium->find_elements('.g');
    
    # 結果を表示
    foreach my $result (@$results) {
        my $title = $selenium->find_element('h3', $result);
        say $selenium->get_text($title) if $title;
    }
    
    # 新しいタブを開く
    my $new_tab = $selenium->create_new_tab();
    
    # 新しいタブでウェブサイトを開く
    $selenium->goto_page('https://www.cpan.org');
    
    # スクリプト終了時に自動的にブラウザが閉じられます

=head1 注意事項

- このモジュールを使用するには、ChromeブラウザとChromeDriverがインストールされている必要があります。
- ヘッドレスモードはCI/CD環境やバックグラウンド処理に適しています。
- User-Agentはランダムに選択されるため、実行ごとに異なる可能性があります。

=head1 著者

あなたの名前 <your.email@example.com>

=head1 ライセンス

このモジュールは自由に使用・改変・再配布が可能です。

=cut
