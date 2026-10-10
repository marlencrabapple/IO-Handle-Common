use Object::Pad ':experimental(:all)';

package IO::Handle::Common;

class IO::Handle::Common : does(IO::Handle::Common::Base);
our $VERSION = '0.01_2';

use utf8;
use v5.40;

use Carp qw'croak';
use Const::Fast;
use Data::Dumper::Names;
use Devel::StackTrace::WithLexicals;
use PadWalker;
use IO::Handle::Common::Base qw'refstr';
use IO::Handle::Common::Handle;
use Time::Piece;
use Const::Fast;
use List::Util qw'any first pairmap';
use builtin;

use parent 'Class::Exporter';
use vars qw'@EXPORT @EXPORT_OK';

@EXPORT = qw(dmsg info success error fatal msg readline prompt);
@EXPORT_OK = (@EXPORT);

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

const my @head_key => qw(info err success fatal msg dmsg);

field $head = {
( map { $_ => false } @head_key )
};

ADJUST : params (:$decorate //= undef) {

    # my $headfield_ptn = join "|", @$prepend_head;
    # const my $headfield_re => qr/($headfield_ptn)+/i;
    if ($decorate) {
        if ( $decorate == 1 ) {
        $self->decorate(builtin::true)
        }
        elsif ( refstr($decorate) eq 'ARRAY' ) {
            const my $headfield_re => eval "qr/(" . join "|",
            @$decorate . ")+/i";
            $$head{$_} = 1 for grep { $_ =~ $headfield_re } @$decorate;
        }
        elsif ( refstr($decorate) eq 'HASH' ) {
            foreach my ( $k, $v ) (%$decorate) {
                $$head{$k} = 1;
                eval "\$${k}_head = [\$v]";
            }
        }
        elsif ($decorate == 0) {
$self->decorate(builtin::false)
        }
    }
    else {
# $self->decorate
    }

    # elsif ( !reftype($prepend_head) && $prepend_head =~ $headfield_re ) {
    #     $self->adjust( $prepend_head, 1 );
    # }
};

method decorate ( $enable = undef, %opt ) {
    if ( defined $enable && !reftype($enable) ) {
        $$head{$_} = $enable ? true : false for keys %$head
    }
    elsif(!$enable) {
        $$head{$_} = !$$head{$_} for keys %$head
    }
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

method writeh( $h, $line, %opt ) {
    $h->refresh( method => 'say', callarg => [$line], %opt );
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

# method getc    {     state $h = $self->refresh( $h, 'getc', fd => *STDIN, mode => 'r', %opt ); }

method outh ( $line, %opt ) {
    %opt = ( fd => *STDOUT, mode => '>' );
    state $h //= IO::Handle::Common::Handle->new(%opt);
    $h = $self->writeh( $h, $line, %opt );
}

method errh ( $line, %opt ) {
    %opt = ( fd => *STDERR, mode => '>' );
    state $h //= IO::Handle::Common::Handle->new(%opt);
    $h = $self->writeh( $h, $line, %opt );
}

method readh ( %opt ) {
    %opt = ( fd => *STDIN, mode => '<', %opt );
    state $h //= IO::Handle::Common::Handle->new(%opt);
    $h = $self->refresh(%opt);
}

method getline (%opt) {
    %opt = ( fd => *STDIN, mode => '<', %opt );
    $self->readh( method => 'getline', %opt );
}

method prompt (%opt) {
    %opt = ( fd => *STDIN, mode => '<', %opt );
    my $prompt = (
        delete $opt{prompt} // sub ( $h, %opt ) {
            print $opt{prompt};
            ( delete $opt{get} )->( $h, %opt );
        }
    );

    $self->readh( on => $prompt, %opt );
}

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
