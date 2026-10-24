use Object::Pad ':experimental(:all)';

package IO::Handle::Common::Handle;

class IO::Handle::Common::Handle : does(IO::Handle::Common::Base);

use utf8;
use v5.40;

no warnings 'experimental::re_strict';
use re 'strict';

use Const::Fast;
use Unicode::UTF8;
use List::Util qw'any none first';
use Path::Tiny ();
use FileHandle;
use IO::Handle;
use IO::Handle::Common::Base qw'refstr';

const our $DEFAULT_LAYER => 'encoding(UTF-8)';

use open ':std', IO => $DEFAULT_LAYER;

field $charset : param = 'UTF-8';
field $fileno;
field $handle : reader(fh)
  ;    # TODO: decipher AUTOLOAD logic that led to charset reader here
field $path;
field $mode      : param = ">";
field $autoflush : param = 1;

sub AUTOLOAD {
    our $AUTOLOAD;

    my $invoke = shift;
    const my $meth_re => qr!^.*::!;
    my $method = ( $AUTOLOAD =~ s/$meth_re//r );

    if ( blessed $invoke && $invoke->isa('IO::Handle::Common::Handle') ) {
        if ( my $charset = $invoke->fh ) {
            $invoke->fh->$method(@_);
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

    $handle = IO::Handle->new;

    if ($fn) {
        $path   = Path::Tiny::path($fn);
        $handle = $path->filehandle($mode);
        $fileno = fileno($handle)
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

    $handle->autoflush($autoflush) if $handle
};

method say ( $say, %opt ) {
    if ( refstr($say) eq 'ARRAY' ) {
        $handle->say($_) for @$say;
    }
    else {
        $handle->say($say);
    }
}

method refresh (%opt) {
    $handle = IO::Handle::Common::Handle->new(
        fd   => $opt{fd},
        mode => $opt{mode}
    ) unless $handle && blessed($handle) && $handle->opened;

    if ( $opt{on} && refstr( $opt{on} ) eq 'CODE' ) {
        ( delete $opt{on} )->( $handle, %opt );
    }

    if ( $opt{method} && $handle->can( $opt{method} ) ) {
        my $package = blessed($handle);
        my $meth    = delete $opt{method};
        die "Named parameter 'callarg' must be an ARRAY"
          if $opt{callarg}
          && refstr( $opt{callarg} ) ne 'ARRAY';
        $handle->$meth( $opt{callarg}->@* );
    }

    $handle->close
      unless any { $_ } ( @opt{qw'keep_open noclose interactive'} );

    $self;
}

method autoflush ( $enable = 1 ) {
    $autoflush = $enable if $autoflush != $enable;
    $handle->autoflush($autoflush);
}

method default_layer : common {
    $DEFAULT_LAYER;
}
