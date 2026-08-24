use Object::Pad ':experimental(:all)';

package IO::Handle::Common::Base;

role IO::Handle::Common::Base;

use v5.40;
use utf8;

use parent 'Exporter';
use vars qw'@EXPORT @EXPORT_OK';
@EXPORT    = ();
@EXPORT_OK = qw(adjust peek_my var_name);

use Const::Fast;
use PadWalker qw'peek_my var_name';

APPLY {
    use v5.40;
    use utf8;
}

method adjust ( $field, $val ) {
    my $varname = var_name( 0, $field );
    eval "$varname = \$val" if $varname;
    $self;
}

