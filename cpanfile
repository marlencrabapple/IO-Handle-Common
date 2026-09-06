requires 'perl', 'v5.40';

requires 'Const::Fast';
requires 'IO::Handle';
requires 'Devel::Trace';
requires 'Data::Dumper::Names';
requires 'Devel::StackTrace::WithLexicals';
requires 'PadWalker';
requires 'Object::Pad';
requires 'FileHandle';
requires 'List::Util';
requires 'Class::Exporter';

on test => sub {
    requires 'Test::More', '0.96'
};

on develop => sub {
    recommends 'Dist::Milla';
    requires 'Module::Build'
}
