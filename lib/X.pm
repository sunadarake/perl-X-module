package X;

use 5.016;
use version 0.77; our $VERSION = version->declare("v0.0.1");
use strict;
use warnings;
use Carp;
use Module::Load;

our $AUTOLOAD;

my %x_std_modules = (

    # Cwd
    'cwd'           => 'Cwd',
    'getcwd'        => 'Cwd',
    'fastcwd'       => 'Cwd',
    'fastgetcwd'    => 'Cwd',
    'getdcwd'       => 'Cwd',
    'abs_path'      => 'Cwd',
    'realpath'      => 'Cwd',
    'fast_abs_path' => 'Cwd',

    # File::Spec::Functions
    'abs2rel'               => 'File::Spec::Functions',
    'canonpath'             => 'File::Spec::Functions',
    'case_tolerant'         => 'File::Spec::Functions',
    'catdir'                => 'File::Spec::Functions',
    'catfile'               => 'File::Spec::Functions',
    'catpath'               => 'File::Spec::Functions',
    'curdir'                => 'File::Spec::Functions',
    'devnull'               => 'File::Spec::Functions',
    'file_name_is_absolute' => 'File::Spec::Functions',
    'no_upwards'            => 'File::Spec::Functions',
    'path'                  => 'File::Spec::Functions',
    'rel2abs'               => 'File::Spec::Functions',
    'rootdir'               => 'File::Spec::Functions',
    'splitdir'              => 'File::Spec::Functions',
    'splitpath'             => 'File::Spec::Functions',
    'tmpdir'                => 'File::Spec::Functions',
    'updir'                 => 'File::Spec::Functions',

    # File::Basename
    'basename'  => 'File::Basename',
    'dirname'   => 'File::Basename',
    'fileparse' => 'File::Basename',

    # File::Compare
    'compare'      => 'File::Compare',
    'compare_text' => 'File::Compare',

    # File::Find
    'find'      => 'File::Find',
    'finddepth' => 'File::Find',

    # File::Copy
    'copy'    => 'File::Copy',
    'cp'      => 'File::Copy',
    'move'    => 'File::Copy',
    'mv'      => 'File::Copy',
    'syscopy' => 'File::Copy',

    # File::Path
    'make_path'   => 'File::Path',
    'mkpath'      => 'File::Path',
    'remove_tree' => 'File::Path',
    'rmtree'      => 'File::Path',

    # File::Temp
    'tempfile' => 'File::Temp',
    'tempdir'  => 'File::Temp',

    # Encode
    'encode' => 'Encode',
    'decode' => 'Encode',

    # List::Util
    'all'        => 'List::Util',
    'any'        => 'List::Util',
    'bootstrap'  => 'List::Util',
    'first'      => 'List::Util',
    'head'       => 'List::Util',
    'max'        => 'List::Util',
    'maxstr'     => 'List::Util',
    'min'        => 'List::Util',
    'minstr'     => 'List::Util',
    'none'       => 'List::Util',
    'notall'     => 'List::Util',
    'pairfirst'  => 'List::Util',
    'pairgrep'   => 'List::Util',
    'pairkeys'   => 'List::Util',
    'pairmap'    => 'List::Util',
    'pairs'      => 'List::Util',
    'pairvalues' => 'List::Util',
    'product'    => 'List::Util',
    'reduce'     => 'List::Util',
    'reductions' => 'List::Util',
    'sample'     => 'List::Util',
    'shuffle'    => 'List::Util',
    'sum'        => 'List::Util',
    'sum0'       => 'List::Util',
    'tail'       => 'List::Util',
    'uniq'       => 'List::Util',
    'uniqint'    => 'List::Util',
    'uniqnum'    => 'List::Util',
    'uniqstr'    => 'List::Util',
    'unpairs'    => 'List::Util',

    # MIME::Base64
    'decode_base64'         => 'MIME::Base64',
    'decode_base64url'      => 'MIME::Base64',
    'decoded_base64_length' => 'MIME::Base64',
    'encode_base64'         => 'MIME::Base64',
    'encode_base64url'      => 'MIME::Base64',
    'encoded_base64_length' => 'MIME::Base64',

    # Digest::SHA
    'sha1'      => 'Digest::SHA',
    'sha224'    => 'Digest::SHA',
    'sha256'    => 'Digest::SHA',
    'sha384'    => 'Digest::SHA',
    'sha512'    => 'Digest::SHA',
    'sha512224' => 'Digest::SHA',
    'sha512256' => 'Digest::SHA',

    'sha1_hex'      => 'Digest::SHA',
    'sha224_hex'    => 'Digest::SHA',
    'sha256_hex'    => 'Digest::SHA',
    'sha384_hex'    => 'Digest::SHA',
    'sha512_hex'    => 'Digest::SHA',
    'sha512224_hex' => 'Digest::SHA',
    'sha512256_hex' => 'Digest::SHA',

    'sha1_base64'      => 'Digest::SHA',
    'sha224_base64'    => 'Digest::SHA',
    'sha256_base64'    => 'Digest::SHA',
    'sha384_base64'    => 'Digest::SHA',
    'sha512_base64'    => 'Digest::SHA',
    'sha512224_base64' => 'Digest::SHA',
    'sha512256_base64' => 'Digest::SHA',

    # Digest::MD5
    'md5'        => 'Digest::MD5',
    'md5_hex'    => 'Digest::MD5',
    'md5_base64' => 'Digest::MD5',

    # JSON::PP
    'encode_json' => 'JSON::PP',
    'decode_json' => 'JSON::PP',

    # HTTP::Tiny
    'http'      => sub { use HTTP::Tiny; HTTP::Tiny->new(@_); },
    'http_tiny' => sub { use HTTP::Tiny; HTTP::Tiny->new(@_); },

    # Time::Piece
    'time_piece' => sub { use Time::Piece; localtime; }

);

sub import {
    my $package = caller;

    no strict 'refs';

    *{"${package}::AUTOLOAD"} = sub {
        our $AUTOLOAD;
        my $function = $AUTOLOAD;
        $function =~ s/.*:://;

        if ( exists $x_std_modules{$function} ) {
            my $module_or_func = $x_std_modules{$function};

            if ( ref($module_or_func) eq 'CODE' ) {
                my $func = $module_or_func;

                return $func->(@_);
            }
            else {
                my $module = $module_or_func;

                Module::Load::load($module) unless _is_module_loaded($module);

                my $func = $module->can($function)
                  or Carp::croak
                  "Undefined subroutine $function in module $module";

                return $func->(@_);
            }

        }
        else {
            Carp::croak "Undefined subroutine &$AUTOLOAD called";
        }
    };
}

sub _is_module_loaded {
    my $module = shift;
    $module =~ s|::|/|g;
    $module .= '.pm';
    return exists $INC{$module};
}

1;
