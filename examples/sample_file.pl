use v5.40;

# モジュールの場所を指定
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../local/lib/perl5";    # スクリプトからの相対パスを指定
    use lib "$FindBin::Bin/../lib";                # スクリプトからの相対パスを指定
}

use utf8::all;
use X;

my $result = ff_basename(__FILE__);

say $result;
