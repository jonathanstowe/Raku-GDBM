#!perl6

use v6.c;
use Test;

use GDBM;

my $file = "hash-test.db";

my $obj;

lives-ok { $obj = GDBM.new($file) }, "create one";

nok $obj.exists("foo"), "non-existent key doesn't exist";

lives-ok { $obj.store("foo", "bar") }, "set a value";
is $obj.fetch("foo"), "bar", "and got it back";
ok $obj.exists("foo"), "and exists";
lives-ok { $obj.delete("foo") }, "delete the value";
nok $obj.exists("foo"), "non-existent key doesn't exist";
lives-ok {
    nok $obj.fetch("foo").defined, "returns undefined if no key";
}, "fetch with non-existent key";





END {
    if $file.IO.e {
        $file.IO.unlink;
    }
}

done-testing;
# vim: expandtab shiftwidth=4 ft=perl6
