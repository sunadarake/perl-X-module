
use v5.40;

package X::HTML;

use utf8::all;
use HTML::HTML5::Parser;
use XML::LibXML::QuerySelector;
use Exporter 'import';

our @EXPORT = qw/
  hp_create_document
  hp_find_element
  hp_find_elements
  hp_get_text
  hp_get_attr
  hp_get_outer_html
  hp_get_inner_html
  hp_remove_doc
  /;

our $document;
our $parser;

sub hp_create_document($html) {
    $parser   = HTML::HTML5::Parser->new;
    $document = $parser->parse_string( $html, { encoding => 'utf-8' } );
    return $document;
}

sub hp_find_element( $doc, $css_selector ) {
    return $doc->querySelector($css_selector);
}

sub hp_find_elements( $doc, $css_selector ) {
    return $doc->querySelectorAll($css_selector);
}

sub hp_get_text($doc) {
    return $doc->textContent();
}

sub hp_get_attr( $doc, $attr ) {
    return $doc->getAttribute($attr);
}

sub hp_get_outer_html($doc) {
    return $doc->toString;
}

sub hp_get_inner_html($doc) {
    return join '', map { $_->toString } $doc->childNodes;
}

sub hp_remove_doc($doc) {
    $doc->parentNode->removeChild($doc);
}

1;
