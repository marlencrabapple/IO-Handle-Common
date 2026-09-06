use Object::Pad ':experimental(:all)';

package IO::Handle::Common;

class IO::Handle::Common : does(IO::Handle::Common::Base);
our $VERSION = '0.01';

use utf8;
use v5.40;

use Carp qw'croak';
use Const::Fast;
use Data::Dumper::Names;
use Devel::StackTrace::WithLexicals;
use PadWalker;
use IO::Handle::Common::Handle;
use Time::Piece;
use Const::Fast;

use parent 'Class::Exporter';
use vars qw'@EXPORT @EXPORT_OK';

@EXPORT    = qw(dmsg info success error fatal msg);
@EXPORT_OK = ( @EXPORT, qw'$io' );

field $debug : param = $ENV{DEBUG} // 0;

field $ddn_uplvl    : param : accessor = 3;
field $trace_indent : param : accessor = $ENV{DEBUG_INDENT}     // 1;
field $skip_frames  : param : accessor = $ENV{DEBUG_SKIPFRAMES} // 1;

field $info_head    : param : accessor = [qw'▶ ▷'];
field $err_head     : param : accessor = ['❌️'];
field $field_head   : param : accessor = [@$err_head];
field $success_head : param : accessor = ['⭕️'];
field $msg_head     : param : accessor = [undef];

# field $dmsg_head    : accessor;

# ADJUST : params (:$dmsg_head = undef) {
#     $dmsg_head //= [
#         sub {
#             $self->headfmt(
#                 Time::Piece->now->to_string('%Y-%m-%d %H:%M:%S%f') );
#         }
#     ]
# };

field $head = {
    info    => undef,
    err     => undef,
    success => undef,
    fatal   => undef,
    msg     => undef,
    dmsg    => undef
};

ADJUST : params (:$prepend_head //= undef) {

    # my $headfield_ptn = join "|", @$prepend_head;
    # const my $headfield_re => qr/($headfield_ptn)+/i;
    if ($prepend_head) {
        if ( $prepend_head == 1 ) {
            @$head = ( 1 x scalar @$head - 1 );
        }
        elsif ( refstr($prepend_head) eq 'ARRAY' ) {
            const my $headfield_re => eval "qr/(" . join "|",
              @$prepend_head . ")+/i";
            $$head{$_} = 1 for grep { $_ =~ $headfield_re } @$prepend_head;
        }
        elsif ( refstr($prepend_head) eq 'HASH' ) {
            foreach my ( $k, $v ) (%$prepend_head) {
                $$head{$k} = 1;
                eval "\$${k}_head = [\$v]";
            }
        }
    }

    # elsif ( !reftype($prepend_head) && $prepend_head =~ $headfield_re ) {
    #     $self->adjust( $prepend_head, 1 );
    # }
};

method $io {
    $self;
}

method writeh( $line, $handle, %opt ) {

    if ( $line isa 'ARRAY' ) {
        $handle->say($_) for $line->@*;
    }
    elsif ( !ref $line ) {
        $handle->say($line);
    }
}

method outh ($line) {
    state $h = IO::Handle::Common::Handle->new( fd => *STDOUT, mode => '>' );
    $self->writeh( $line, $h );
}

method errh ($line) {
    state $h = IO::Handle::Common::Handle->new( fd => *STDERR, mode => '>' );
    $self->writeh( $line, $h );
}

const our $ltrimtab_re => qr/^\t/;
const our $lb_re       => qr/\R/;

method dmsg {
    return unless $debug // $ENV{DEBUG};
    my @caller = caller 1;

    local $Data::Dumper::Names::UpLevel = $ddn_uplvl;
    local $Data::Dumper::Pad            = "  ";
    local $Data::Dumper::Indent         = 1;

    my $out;
    $out .= Dumper(@_);
    $out .=
      $debug && $debug == 2
      ? join "\n",
      map { ( my $line = $_ ) =~ s/$ltrimtab_re/  /; "  $line" } split /$lb_re/,
      Devel::StackTrace::WithLexicals->new(
        indent      => $trace_indent // 1,
        skip_frames => $skip_frames  // 1
      )->as_string
      : "at $caller[1]:$caller[2]\n";

    $self->errh($out);
    $out;
}

method info ($line) {
    $line = "$info_head $line" if $$head{info};
    $self->errh($line);
}

method error ($line) {
    $line = "$err_head $line" if $$head{error};
    $self->errh($line);
}

method fatal ( $line, $status = ( $? || 255 ), %opt ) {
    $status = $status >> 8 if ( $status > 255 );

    error "Status ($status) must be between 0 and 255"
      unless $status >= 0 || $status <= 255;

    $self->error( $line, %opt );
    croak $status;
}

method success ($line) {
    $line = "$success_head $line" if $$head{success};
    $self->outh($line);
}

method msg ($line) {
    $self->outh( ( $$head{msg} // '' ) . $line );
}

# method headfmt( $instr, %opt ) {
#     $instr;
# }

# method prompt  { ... }
# method getc    { ... }
# method getline { ... }

=encoding utf-8

=head1 NAME

IO::Handle::Common - Nearly ubiquitous methods for script and file IO

=head1 SYNOPSIS

  use IO::Handle::Common; # Exports info, error, fatal, success, msg, dmsg and path by default

  # Pretty-print @args only if $debug || $ENV{DEBUG} is set to something truth-y
  dmsg ...; #

  fatal "$?..." if $?; # die without line numbers or other non-enduser information

  success "..." # ...

=head1 DESCRIPTION

IO::Handle::Common is a collection of methods useful for script output, both
debug and user-facing, and file-based IO wrapped loosely around IO::Handle and
Path::Tiny.

=head1 AUTHOR

Ian P Bradley E<lt>ian@pennyfoss.orgE<gt>

=head1 COPYRIGHT

Copyright 2026- Ian P Bradley

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
