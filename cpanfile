requires 'perl', 'v5.40';

requires 'Const::Fast';
requires 'IO::Handle';
requires 'Path::Tiny';
requires 'Data::Dumper::Names';
requires 'Devel::StackTrace::WithLexicals';
requires 'PadWalker';
requires 'FileHandle';
requires 'List::Util';

on test => sub {
    requires 'Test::More', '0.96';
};
