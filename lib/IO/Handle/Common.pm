use Object::Pad ':experimental(:all)';

package IO::Handle::Common;

class IO::Handle::Common : does(IO::Handle::Common::Base);
our $VERSION = '0.01_05';

use utf8;
use v5.44;

use Carp qw'croak';
use Const::Fast;
use Data::Dumper::Names;
use Devel::StackTrace::WithLexicals;
use PadWalker;

# use IO::Handle::Common::Base qw'refstr';
use IO::Handle::Common::Handle;
use Time::Piece;
use Const::Fast;
use List::Util qw'any first pairmap none';
use builtin;

use parent 'Class::Exporter';
use vars qw'$io @EXPORT @EXPORT_OK';

@EXPORT    = qw(IO dmsg info success error fatal msg getline prompt);
@EXPORT_OK = (@EXPORT);

field $debug : param = $ENV{DEBUG} // 0;

field $dmsg_uplevel      : param : accessor = 3;
field $dmsg_trace_indent : param : accessor = $ENV{DEBUG_INDENT}     // 1;
field $dmsg_skip_frames  : param : accessor = $ENV{DEBUG_SKIPFRAMES} // 2;
field $dmsg_pad          : param : accessor = "  ";
field $dmsg_indent       : param : accessor = 1;

field $info_head    : param : accessor = [qw'▶ ▷'];
field $err_head     : param : accessor = ['❌️'];
field $fatal_head   : param : accessor = [@$err_head];
field $success_head : param : accessor = ['⭕️'];
field $msg_head     : param : accessor = [undef];

field $in : reader =
  IO::Handle::Common::Handle->new( fd => *STDIN, mode => '<' );
field $out : reader =
  IO::Handle::Common::Handle->new( fd => *STDOUT, mode => '>' );
field $err : reader =
  IO::Handle::Common::Handle->new( fd => *STDERR, mode => '>' );

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

field $head //= { ( map { $_ => false } @head_key ) };

ADJUST : params (:$decorate //= undef) {

    # my $headfield_ptn = join "|", @$prepend_head;
    # const my $headfield_re => qr/($headfield_ptn)+/i;
    if ($decorate) {
        if ( $decorate == 1 ) {
            $self->decorate(builtin::true);
        }
        elsif ( refstr($decorate) eq 'ARRAY' ) {
            const my $headfield_re => eval "qr/(" . join "|",
              @$decorate . ")+/i";
            $$head{$_} = 1 for grep { $_ =~ $headfield_re } @$decorate;
        }
        elsif ( refstr($decorate) eq 'HASH' ) {
            foreach my ( $k, $v ) (%$decorate) {
                $$head{$k} = 1;
                $self->dmsg( eval "\$${k}_head = [\$v]" );
            }
        }
        elsif ( $decorate == 0 ) {
            $self->decorate(builtin::false);
        }
    }
    else {
        # $self->decorate
    }

    # elsif ( !reftype($prepend_head) && $prepend_head =~ $headfield_re ) {
    #     $self->adjust( $prepend_head, 1 );
    # }
};

method IO {
    $self;
}

method decorate( $enable = undef, %opt ) {

    if ( defined $enable && !reftype($enable) ) {
        $$head{$_} = $enable ? true : false for keys %$head;
    }
    elsif ( !$enable ) {
        $$head{$_} = !$$head{$_} for keys %$head;
    }
}

const our $ltrimtab_re => qr/^\t/;
const our $lb_re       => qr/\R/;

method dmsg (@var) {
    return unless $debug // $ENV{DEBUG};

    my %opt;
    my $i = scalar @var - 1;
    
    foreach my ( $v, $k ) ( reverse @var ) {
        next
          if none { $k && $k eq $_ }
          qw'trace uplevel pad indent trace_indent skip_frames';

        $opt{$k} //= $v;
        sub ($i) { delete $var[$_] if exists $var[$_] }
          ->($_) for $i, $i--;
    }

    my @caller = caller 1;

    local $Data::Dumper::Names::UpLevel = $opt{uplevel} // $dmsg_uplevel;
    local $Data::Dumper::Pad            = $opt{pad}     // $dmsg_pad;
    local $Data::Dumper::Indent         = $opt{indent}  // $dmsg_indent;

    my $out;
    $out .= Dumper(@var);
    $out .=
      ( $opt{trace} || $debug == 2 )
      ? join "\n",
      map { ( my $line = $_ ) =~ s/$ltrimtab_re/  /; "  $line" } split /$lb_re/,
      Devel::StackTrace::WithLexicals->new(
        indent      => $opt{trace_indent} // $dmsg_trace_indent,
        skip_frames => $opt{skip_frames}  // $dmsg_skip_frames
      )->as_string
      : "at $caller[1]:$caller[2]\n";

    $self->writeh( $err, $out );
    $out;
}

method readh ( $h //= $in, %opt ) {
    ( $h = ref $h ? $h : $self->$h )->refresh(%opt);
}

method writeh( $h, $line, %opt ) {
    const my $headkey_re => qr/_head$/;
    my $headfield = $opt{headfield};
    my $head =
      ( $opt{headfield} && $$head{ ( $opt{headfield} =~ s/$headkey_re//gr ) } )
      ? $self->$headfield->[0]
      : undef;

    $line = "$head $line" if $head;

    ( $h = ref $h ? $h : $self->$h )
      ->refresh( method => 'say', callarg => [$line], keep_open => 1, %opt );
}

method info ( $line, %opt ) {
    $line = "$$info_head[0] $line" if $$head{info};
    $self->writeh( delete $opt{handle} // $err, $line, %opt );
}

method error ( $line, %opt ) {

    # my $head =
    #   $opt{headfield} && $$head{ $opt{headfield} }
    #   ? eval "\$\$$opt{headfield}[0]"
    #   : $$err_head[0];

    $line = "$$err_head[0] $line" if $$head{err};
    $self->writeh( delete $opt{handle} // $err, $line, %opt );
}

method fatal ( $line, $status = ( $? || 255 ), %opt ) {
    $status = $status >> 8 if ( $status > 255 );
    $opt{headfield} //= 'fatal_head';

    error "Status ($status) must be between 0 and 255", %opt,
      unless $status >= 0 || $status <= 255;

    $self->writeh( delete $opt{handle} // $err, $line, %opt );
    croak $status;
}

method success ( $line, $handle = $out ) {
    $line = "$$success_head[0] $line" if $$head{success};
    $self->writeh( $handle, $line );
}

method msg ( $line, $handle = $out ) {
    $self->writeh( $handle, ( $$msg_head[0] // '' ) . $line );
}

# method headfmt( $instr, %opt ) {
#     $instr;
# }

# method getc    {     state $h = $self->refresh( $h, 'getc', fd => *STDIN, mode => 'r', %opt ); }

method getline (%opt) {
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
