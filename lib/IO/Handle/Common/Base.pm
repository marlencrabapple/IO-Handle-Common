use Object::Pad ':experimental(:all)';

package IO::Handle::Common::Base;

role IO::Handle::Common::Base;

use v5.40;
use utf8;

use parent 'Exporter';
use Unicode::UTF8;
use Const::Fast;
use PadWalker qw'peek_my var_name';

use subs 'array';
use vars qw'@EXPORT @EXPORT_OK';

@EXPORT_OK = qw'refstr array ARRAY';
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

sub ARRAY (@in) {
    my @ret;

    foreach my ($var) (@in) {
        $var //= [];
        my $type = reftype($var);

        if ( !$type ) {
            push @ret, [$var];
        }
        elsif ( $type ne 'ARRAY' ) {
            my $name = PadWalker::var_name( 0, $var );
            die "\$name must be an ARRAY ref or a scalar value. (Got: $type)";
        }
        elsif ( $type eq 'ARRAY' ) {
            push @ret, $var;
        }
    }

    # use Data::Dumper;
    # say STDERR Dumper( \@in, \@ret );
    @ret;
}

*array = \&ARRAY;

