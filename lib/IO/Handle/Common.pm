use Object::Pad ':experimental(:all)';

package IO::Handle::Common;

class IO::Handle::Common;

our $VERSION = '0.01';

use utf8;
use v5.40;

use Const::Fast;
use Data::Dumper::Names;
use Devel::StackTrace::WithLexicals;
use PadWalker;
use IO::Handle::Common::Handle;
use Path::Tiny qw'';

use base 'Class::Exporter';
use vars qw'@EXPORT @EXPORT_OK';

@EXPORT = qw($io dmsg info success error fatal msg path);

field $debug = $ENV{DEBUG} // 1;

field $ddn_uplvl    : param : accessor = 3;
field $trace_indent : param : accessor = $ENV{DEBUG_INDENT}     // 1;
field $skip_frames  : param : accessor = $ENV{DEBUG_SKIPFRAMES} // 1;

field $linestart_info    : param : accessor = '▶';
field $linestart_err     : param : accessor = '❌️';
field $linestart_success : param : accessor = '⭕️';

method $io {
    $self;
}

method path {
    Path::Tiny::path(@_);
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
    return unless $debug = $ENV{DEBUG};
    my @caller = caller 1;

    local $Data::Dumper::Names::UpLevel = $ddn_uplvl;
    local $Data::Dumper::Pad            = "  ";
    local $Data::Dumper::Indent         = 1;

    my $out;
    $out .= Dumper(@_);
    $out .=
      $debug && $debug == 2
      ? join "\n",
      map { ( my $line = $_ ) =~ s/$ltrimtab_re/  /; "  $line" } split $lb_re,
      Devel::StackTrace::WithLexicals->new(
        indent      => $trace_indent // 1,
        skip_frames => $skip_frames  // 1
      )->as_string
      : "at $caller[1]:$caller[2]\n";

    $self->errh($out);
    $out;
}

method info ($line) {
    $line = "$linestart_info $line" if $linestart_info;
    $self->errh($line);
}

method error ($line) {
    $line = "$linestart_err $line" if $linestart_err;
    $self->errh($line);
}

method fatal ( $line, $status = ( $? || 255 ), %opt ) {
    $self->error($line);
    exit $status;
}

method success ($line) {
    $line = "$linestart_success $line" if $linestart_success;
    $self->outh($line);
}

method msg ($line) {
    $self->outh($line);
}

method prompt  { ... }
method getc    { ... }
method getline { ... }

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
