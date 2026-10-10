use Object::Pad ':experimental(:all)';

package IO::Handle::Common::Base;

role IO::Handle::Common::Base;

use v5.40;
use utf8;

use parent 'Exporter';

use Const::Fast;
use PadWalker qw'peek_my var_name';

BEGIN {
    use vars qw'@EXPORT @EXPORT_OK';
    @EXPORT    = ();
    @EXPORT_OK = qw(refstr adjust peek_my var_name);
}

APPLY {
    use v5.40;
    use utf8;

    use IO::Handle::Common::Base qw'refstr'
}

method adjust ( $field, $val ) {
    my $varname = var_name( 0, $field );
    eval "$varname = \$val" if $varname;
    $self;
}

sub refstr ($in) {
    reftype($in) || '';
}

