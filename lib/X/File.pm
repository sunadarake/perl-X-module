
package X::File;

use v5.40;
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
