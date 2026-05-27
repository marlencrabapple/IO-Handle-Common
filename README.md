# NAME

IO::Handle::Common - Nearly ubiquitous methods for script and file IO

# SYNOPSIS

    use IO::Handle::Common; # Exports info, error, fatal, success, msg, dmsg and path by default

    # Pretty-print @args only if $debug || $ENV{DEBUG} is set to something truth-y
    dmsg ...; #

    fatal "$?..." if $?; # die without line numbers or other non-enduser information

    success "..." # ...

# DESCRIPTION

IO::Handle::Common is a collection of methods useful for script output, both
debug and user-facing, and file-based IO wrapped loosely around IO::Handle and
Path::Tiny.

# AUTHOR

Ian P Bradley <ian@pennyfoss.org>

# COPYRIGHT

Copyright 2026- Ian P Bradley

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO
