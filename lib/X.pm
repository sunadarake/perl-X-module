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
    'http'           => sub { use HTTP::Tiny; HTTP::Tiny->new(@_); },
    'http_tiny'      => sub { use HTTP::Tiny; HTTP::Tiny->new(@_); },
    'http_get'       => sub { _http_tiny_request( 'GET',    @_ ) },
    'http_post'      => sub { _http_tiny_request( 'POST',   @_ ) },
    'http_put'       => sub { _http_tiny_request( 'PUT',    @_ ) },
    'http_delete'    => sub { _http_tiny_request( 'DELETE', @_ ) },
    'http_patch'     => sub { _http_tiny_request( 'PATCH',  @_ ) },
    'http_head'      => sub { _http_tiny_request( 'HEAD',   @_ ) },
    'http_post_form' => sub { _http_tiny_post_form(@_) },
    'http_mirror'    => sub { _http_tiny_mirror(@_) },

    # Time::Piece
    'time_piece' => sub { use Time::Piece; localtime; },

    # file read write
    'fread'          => sub { _file_util_fread(@_) },
    'fwrite'         => sub { _file_util_fwrite(@_) },
    'find_files'     => sub { _find_files_abs(@_) },
    'ffind'          => sub { _find_files_abs(@_) },
    'find_files_abs' => sub { _find_files_abs(@_) },
    'ffind_abs'      => sub { _find_files_abs(@_) },
    'find_files_rel' => sub { _find_files_rel(@_) },
    'ffind_rel'      => sub { _find_files_rel(@_) },

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

sub _http_tiny_request {
    my ( $meth, $url, $options ) = @_;

    $options ||= +{};

    use HTTP::Tiny;
    my $res = HTTP::Tiny->new->$meth( $url, $options );

    if ( $res->{success} ) {
        return $res->{content};
    }
    else {
        Carp::croak "Failed http request: $res->{status} $res->{reason}\n";
    }

}

sub _http_tiny_post_form {
    my ( $url, $form_data, $options ) = @_;

    $options ||= +{};

    use HTTP::Tiny;
    my $res = HTTP::Tiny->new->post_form( $url, $form_data, $options );

    unless ( $res->{success} ) {
        Carp::croak "Failed http mirror: $res->{status} $res->{reason}\n";
    }
}

sub _http_tiny_mirror {
    my ( $url, $file, $options ) = @_;

    $options ||= +{};

    use HTTP::Tiny;
    my $res = HTTP::Tiny->new->mirror( $url, $file, $options );

    unless ( $res->{success} ) {
        Carp::croak "Failed http mirror: $res->{status} $res->{reason}\n";
    }
}

sub _file_util_fread {
    my ( $file, $encoding ) = @_;
    $encoding //= 'utf8';

    open my $fh, qq{<:encoding('$encoding')}, $file
      or Carp::croak qq{Could not open file '$file': $!};
    local $/;
    my $content = <$fh>;
    close $fh;
    return $content;
}

sub _file_util_fwrite {
    my ( $file, $content, $encoding ) = @_;
    $encoding //= 'utf8';

    open my $fh, qq{>:encoding('$encoding')}, $file
      or Carp::croak qq{Could not open file '$file': $!};

    print $fh $content or Carp::croak qq{Could not write to file '$file': $!};

    close $fh;
}

sub _find_files_abs {
    my ($dir) = @_;
    my @files;

    use File::Find;

    find(
        sub {
            return if -d;
            push @files, $File::Find::name;
        },
        $dir
    );

    return @files;
}

sub _find_files_rel {
    my ($dir) = @_;
    my @files;

    use File::Find;

    find(
        sub {
            return if -d;
            push @files, $_;
        },
        $dir
    );

    return @files;
}

1;
