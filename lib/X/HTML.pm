
use v5.40;
use utf8::all;

package X::HTML {
    use Moo;
    use HTML::HTML5::Parser;
    use XML::LibXML::QuerySelector;

    # parser自身
    has parser => (
        is       => "ro",
        required => 1,
    );

    # parserがhtmlを解釈した跡のdocument object
    has document => (
        is       => "ro",
        required => 1,
    );

    # 生のhtmk string
    has html => (
        is       => "ro",
        required => 1,
    );

    sub create_document( $class, $html ) {
        my $parser = HTML::HTML5::Parser->new;

        my $document = $parser->parse_string( $html, { encoding => 'utf-8' } );

        return $class->new(
            parser   => $parser,
            document => $document,
            html     => $html,
        );
    }

}

1;
