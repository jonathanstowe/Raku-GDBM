#!perl6

use v6;
use Test;

use GDBM;

my $obj;

lives-ok { $obj = GDBM.new('foo.db') }, "create one";

isa-ok $obj, GDBM, "and it's the right sort of object";

ok 'foo.db'.IO.e, "and the file exists";

"foo.db".IO.unlink;

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
