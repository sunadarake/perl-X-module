
use v5.40;

package X::File;

use utf8::all;
use File::Find qw(find);
use File::Spec;
use File::Basename qw(dirname basename fileparse);
use File::Path     qw(make_path);
use Cwd            qw(abs_path);
use Exporter 'import';

our @EXPORT = qw(
  ff_file_put_contents
  ff_file_get_contents
  ff_find_file_abs
  ff_find_file_rel
  ff_join_path
  ff_make_dir
  ff_dirname
  ff_basename
  ff_basename_without_ext
  ff_get_extention
  ff_file_to_abs
  ff_is_dir_exists
);

sub ff_file_put_contents( $file_path, $content ) {
    my $_dir = dirname $file_path;
    make_path $_dir unless -d $_dir;

    open my $fh, '>', $file_path
      or die "Failed to open file $file_path for writing: $!";
    print $fh $content;
    close $fh or die "Failed to close file $file_path: $!";

    return 1;
}

# Read content from a file
sub ff_file_get_contents($file_path) {
    open my $fh, '<', $file_path
      or die "Failed to open file $file_path for reading: $!";
    my $content = do { local $/; <$fh> };
    close $fh or die "Failed to close file $file_path: $!";

    return $content;
}

# 指定ディレクトリ内のファイルを絶対パスで再帰的に検索する
# @param $root_dir - 検索を開始するルートディレクトリ
# @param $ext - 検索する拡張子（省略可）
# @return - 見つかったファイルの絶対パスの配列リファレンス
sub ff_find_file_abs ( $root_dir, $ext = undef ) {

    my @found_files;
    find(
        {
            wanted => sub {

                # ディレクトリでなく、ファイルのみを対象とする
                return unless -f $_;

                # 拡張子が指定されている場合はフィルタリング
                if ( defined $ext ) {
                    return unless $_ =~ /\.$ext$/;
                }

                # 絶対パスに変換して配列に追加
                push @found_files, abs_path($File::Find::name);
            },
            no_chdir => 1,
        },
        $root_dir
    );

    return \@found_files;
}

# 指定ディレクトリ内のファイルを相対パスで再帰的に検索する
# @param $root_dir - 検索を開始するルートディレクトリ
# @param $ext - 検索する拡張子（省略可）
# @return - 見つかったファイルの相対パスの配列リファレンス
sub ff_find_file_rel ( $root_dir, $ext = undef ) {

    # rootディレクトリの絶対パスを取得
    my $abs_root_dir    = abs_path($root_dir);
    my $root_dir_length = length($abs_root_dir) + 1;    # +1 はパス区切り文字の分

    my @found_files;
    find(
        {
            wanted => sub {

                # ディレクトリでなく、ファイルのみを対象とする
                return unless -f $_;

                # 拡張子が指定されている場合はフィルタリング
                if ( defined $ext ) {
                    return unless $_ =~ /\.$ext$/;
                }

                # 相対パスを作成して配列に追加
                my $abs_path = abs_path($File::Find::name);
                my $rel_path = substr( $abs_path, $root_dir_length );
                push @found_files, $rel_path;
            },
            no_chdir => 1,
        },
        $root_dir
    );

    return \@found_files;
}

# 複数のパス要素を結合して一つのパスを作成する
# @param @parts - 結合するパス要素（可変長引数）
# @return - 結合されたパス
sub ff_join_path (@parts) {
    my $result = File::Spec->catfile(@parts);
    return abs_path($result);
}

# ディレクトリを作成する（必要に応じて親ディレクトリも作成）
# @param $src_dir - 作成するディレクトリパス
# @return - 成功した場合は作成したディレクトリの数、失敗した場合はundef
sub ff_make_dir ($src_dir) {
    unless ( -d $src_dir ) {
        my $result = make_path( $src_dir, { verbose => 1 } );
        say "ディレクトリ作成: $src_dir";
        return $result;
    }
    else {
        return undef;
    }
}

# ファイルパスからディレクトリ名部分を取得する
# @param $file_path - ファイルパス
# @return - ディレクトリ名
sub ff_dirname ($file_path) {
    return dirname($file_path);
}

# ファイルパスからファイル名部分を取得する
# @param $file_path - ファイルパス
# @return - ファイル名
sub ff_basename ($file_path) {
    return basename($file_path);
}

# ファイルパスから拡張子を除いたファイル名を取得する
# @param $file_path - ファイルパス
# @return - 拡張子を除いたファイル名
sub ff_basename_without_ext ($file_path) {
    my ( $name, $path, $suffix ) = fileparse( $file_path, qr/\.[^.]*/ );
    return $name;
}

sub ff_get_extention ($file_path) {
    my ( $name, $path, $suffix ) = fileparse( $file_path, qr/\.[^.]*/ );
    return $suffix;
}

sub ff_file_to_abs($file_path) {
    return abs_path( File::Spec->canonpath($file_path) );
}

sub ff_is_dir_exists($dir_path) {
    my $abs_path = abs_path( File::Spec->canonpath($dir_path) );
    return 1 if -d $abs_path;
    return 0;
}

1;

=encoding utf8

=head1 名称

X::File - ファイル操作を簡略化するユーティリティ関数群

=head1 概略

    use X::File;
    
    # ファイルに内容を書き込む
    ff_file_put_contents('path/to/file.txt', 'ファイルの内容');
    
    # ファイルから内容を読み込む
    my $content = ff_file_get_contents('path/to/file.txt');
    
    # ディレクトリ内のファイルを検索
    my $files = ff_find_file_abs('path/to/dir', 'txt');

=head1 説明

このモジュールは、ファイル操作に関する一般的なタスクを簡略化するための関数コレクションを提供する。
ファイルの読み書き、パス操作、ディレクトリ作成、ファイル検索などの機能が含まれる。

=head1 関数

=head2 ff_file_put_contents

ファイルに内容を書き込む。必要に応じて親ディレクトリも作成する。

- パラメータ1: $file_path (Str) - 書き込み先のファイルパス
- パラメータ2: $content (Str) - ファイルに書き込む内容
- 戻り値: (Bool) - 成功した場合は1

=head2 ff_file_get_contents

ファイルの内容を読み込む。

- パラメータ: $file_path (Str) - 読み込むファイルのパス
- 戻り値: (Str) - ファイルの内容

=head2 ff_find_file_abs

指定ディレクトリ内のファイルを絶対パスで再帰的に検索する。

- パラメータ1: $root_dir (Str) - 検索を開始するルートディレクトリ
- パラメータ2: $ext (Str, optional) - 検索する拡張子（省略可）
- 戻り値: (ArrayRef[Str]) - 見つかったファイルの絶対パスの配列リファレンス

=head2 ff_find_file_rel

指定ディレクトリ内のファイルを相対パスで再帰的に検索する。

- パラメータ1: $root_dir (Str) - 検索を開始するルートディレクトリ
- パラメータ2: $ext (Str, optional) - 検索する拡張子（省略可）
- 戻り値: (ArrayRef[Str]) - 見つかったファイルの相対パスの配列リファレンス

=head2 ff_join_path

複数のパス要素を結合して一つのパスを作成する。

- パラメータ: @parts (Array[Str]) - 結合するパス要素（可変長引数）
- 戻り値: (Str) - 結合された絶対パス

=head2 ff_make_dir

ディレクトリを作成する。必要に応じて親ディレクトリも作成する。

- パラメータ: $src_dir (Str) - 作成するディレクトリパス
- 戻り値: (Int|Undef) - 成功した場合は作成したディレクトリの数、既に存在する場合はundef

=head2 ff_dirname

ファイルパスからディレクトリ名部分を取得する。

- パラメータ: $file_path (Str) - ファイルパス
- 戻り値: (Str) - ディレクトリ名

=head2 ff_basename

ファイルパスからファイル名部分を取得する。

- パラメータ: $file_path (Str) - ファイルパス
- 戻り値: (Str) - ファイル名

=head2 ff_basename_without_ext

ファイルパスから拡張子を除いたファイル名を取得する。

- パラメータ: $file_path (Str) - ファイルパス
- 戻り値: (Str) - 拡張子を除いたファイル名

=head2 ff_get_extention

ファイルパスから拡張子を取得する。

- パラメータ: $file_path (Str) - ファイルパス
- 戻り値: (Str) - 拡張子（ドット含む）

=head2 ff_file_to_abs

相対パスを絶対パスに変換する。

- パラメータ: $file_path (Str) - 変換するファイルパス
- 戻り値: (Str) - 正規化された絶対パス

=head2 ff_is_dir_exists

指定されたディレクトリが存在するかを確認する。

- パラメータ: $dir_path (Str) - 確認するディレクトリパス
- 戻り値: (Bool) - ディレクトリが存在する場合は1、存在しない場合は0

=cut
