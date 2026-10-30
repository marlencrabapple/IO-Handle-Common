use Object::Pad ':experimental(:all)';

package IO::Handle::Common::Base;

role IO::Handle::Common::Base;

use v5.40;
use utf8;

use parent 'Exporter';
use Unicode::UTF8;
use Const::Fast;
use PadWalker qw'peek_my var_name';

use vars qw'@EXPORT @EXPORT_OK';

@EXPORT_OK = qw'refstr';
@EXPORT    = @EXPORT_OK;

our @EXPORT_SUB    = @EXPORT_OK;
our @EXPORT_COMMON = qw'';

field $imported : reader;

APPLY($class_mop) {
    __PACKAGE__->apply($class_mop)
};

ADJUST {
    $self->import;
}

method apply : common ($class_mop) {
    $class->export_sub($class_mop);
    $class->export_common($class_mop);
}

method export_sub : common ($class_mop) {
    foreach my $common (@EXPORT_SUB) {
        $class_mop->add_method( $common, common => 1, \&$common );
    }
}

method export_common : common ($class_mop) {
    my $class = $class_mop->name;
    foreach my $common (@EXPORT_COMMON) {
        $class_mop->add_method( $common, common => 1, sub { $class->$common } );
    }
}

method adjust ( $field, $val ) {
    my $varname = var_name( 0, $field );
    eval "$varname = \$val" if $varname;
    $self;
}

sub refstr ($in) {
    reftype($in) || '';
}

