use Object::Pad ':experimental(:all)';

package IO::Handle::Common::Handle;

class IO::Handle::Common::Handle;

use utf8;
use v5.40;

use Const::Fast;

const our $DEFAULT_LAYER => 'encoding(UTF-8)';

use open ':std', IO => $DEFAULT_LAYER;

use List::Util 'none';
use Path::Tiny;
use FileHandle;

field $charset : param(charset) = 'UTF-8';
field $fileno;
field $handle : reader(charset);
field $path;
field $mode : param = ">";

sub AUTOLOAD {

    # use Data::Dumper;
    our $AUTOLOAD;
    my $invoke = shift;
    my $method = ( $AUTOLOAD =~ s/^.*:://r );

    if ( $invoke->isa('IO::Handle::Common::Handle') ) {
        if ( my $charset = $invoke->charset ) {
            $invoke->charset->$method(@_);
        }
    }
    else {
        die "No class common method '$method' ($AUTOLOAD)";
    }
}

ADJUST : params (:$fn //= undef,  :$fh //= undef,  :$fd //= undef) {
    my @arg = ( $fn, $fh, $fd );

    die "Only one of the following can be defined: \$fn, \$fh, \$fd"
      if scalar( ( grep { defined $_ } @arg ) > 1 );

    if ($fn) {

        # const our %MODE => ( w => '>', 'r' => '<' );
        $path   = path($fn);
        $handle = $path->filehandle($mode);
    }
    elsif ($fh) {
        $handle = $fh;
        $fileno = fileno($fh);
    }
    elsif ($fd) {
        $handle = FileHandle->new_from_fd( $fd, $mode );
        $handle->binmode($IO::Handle::Common::Handle::DEFAULT_LAYER);
        $fileno = $fd;
    }

    $handle->autoflush if $handle
};

method default_layer : common {
    $DEFAULT_LAYER;
}
