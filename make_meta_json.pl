#!/usr/bin/env perl

use v5.40;
use utf8::all;
use Module::CPANfile;
use CPAN::Meta;
use JSON::PP;
use Carp 'croak';

try {

    # cpanfile を読み込む
    my $cpanfile = Module::CPANfile->load('./cpanfile');

    # メタデータのベースを作成
    my $meta = {
        version        => 'v0.1.0',
        abstract       => "A module for Perl one-liners",
        authors        => ['Sunadarake <sunadarake9@gmail.com>'],
        dynamic_config => 0,
        licenses       => ["perl_5"],
        name           => "X",
        no_index       => {
            directory => [
                "t",  "xt",       "inc",    "share",
                "eg", "examples", "author", "builder"
            ]
        },
        prereqs      => $cpanfile->prereqs->as_string_hash,
        generated_by => 'Sunadarake',
        meta_spec    => {
            version => 2,
            url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
        },
        release_status => 'unstable',
        resources      => {
            bugtracker => {
                web => 'https://github.com/sunadarake/perl-X-module',
            },
            homepage   => 'https://github.com/sunadarake/perl-X-module',
            repository => {
                type => 'git',
                url  => 'git://github.com/sunadarake/perl-X-module',
                web  => 'https://github.com/sunadarake/perl-X-module',
            },
        },

        x_static_install => 1,
    };

    # CPAN::Meta オブジェクトを作成
    my $cm = CPAN::Meta->new($meta);

    # META.json を出力
    open my $fh, '>', 'META.json' or die "Cannot open META.json: $!";
    print $fh JSON::PP->new->pretty->encode( $cm->as_struct );
    close $fh;

    say "META.json has been generated.\n";

}
catch ($e) {
    croak "ERROR: $e";
}
