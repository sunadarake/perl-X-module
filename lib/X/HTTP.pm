
use v5.40;

package X::HTTP;

use utf8::all;
use HTTP::Tiny;
use JSON;

# MP4ファイルをダウンロードする関数
# @param $mp4_url - ダウンロードするMP4ファイルのURL
# @param $dest_path - 保存先のパス
# @return - 成功した場合は1、失敗した場合は0
sub http_download_mp4 ( $mp4_url, $dest_path ) {
    say "MP4ダウンロードを開始します: $mp4_url -> $dest_path";

    # 保存先ディレクトリが存在しない場合は作成
    my $dir = dirname($dest_path);
    make_path($dir) unless -d $dir;

    my $client = HTTP::Tiny->new;

    # ダウンロードを実行
    my $res = $client->get(
        $mp4_url,
        {
            data_callback => sub {
                my ( $data, $res ) = @_;

                # ファイルに追記モードで書き込み
                open my $fh, '>>', $dest_path or do {
                    warn "ファイル $dest_path を開けませんでした: $!";
                    return 0;
                };

                binmode $fh;
                print $fh $data;
                close $fh;
            }
        }
    );

    if ( $res->{success} ) {
        say "MP4ダウンロードが完了しました: $dest_path";
        return 1;
    }
    else {
        say "MP4ダウンロードに失敗しました: $res->{status} $res->{reason} $res->{content}";
        return 0;
    }
}

# HTTPのGETリクエストを実行する関数
# @param $url - リクエスト先のURL
# @param $option - HTTP::Tinyのオプション (ハッシュリファレンス)
# @return - レスポンスの内容
sub http_get ( $url, $option = {} ) {
    say "HTTP GETリクエストを実行します: $url";

    my $client = HTTP::Tiny->new;

    my $res = $client->get( $url, $option );

    if ( $res->{success} ) {
        say "HTTP GETリクエストが成功しました: $url";
        return $res->{content};
    }
    else {
        say "HTTP GETリクエストに失敗しました: $res->{status} $res->{reason}";
        return undef;
    }
}

1;
