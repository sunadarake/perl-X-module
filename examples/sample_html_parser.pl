use v5.40;

# モジュールの場所を指定
BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/../local/lib/perl5";    # スクリプトからの相対パスを指定
    use lib "$FindBin::Bin/../lib";                # スクリプトからの相対パスを指定
}

use utf8::all;
use X;
use HTTP::Tiny;
use HTML::HTML5::Parser;
use XML::LibXML::QuerySelector;

my $url  = 'https://www.example.com/';
my $http = HTTP::Tiny->new;

my $res = $http->get($url);

my $html = $res->{content};

say $html;

my $doc = hp_create_document($html);

my $h1_tag = hp_find_element( $doc, "h1" );

my $p_tags = hp_find_elements( $doc, "p" );

my $result = hp_get_text($h1_tag);

say $result;
