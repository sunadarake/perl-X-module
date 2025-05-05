use v5.40;

# モジュールの場所を指定
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../local/lib/perl5";    # スクリプトからの相対パスを指定
    use lib "$FindBin::Bin/../lib";                # スクリプトからの相対パスを指定
}

use utf8::all;
use X;

my $db_path = "./sample.sqlite3";

my $db = X::DB->connect_database( $db_path, "samples" );

$db->insert(
    {
        name => "hellow",
    }
);

$db->table("foobar");

my $results = $db->find_all();

for my $row (@$results) {
    say $row->name;
}
