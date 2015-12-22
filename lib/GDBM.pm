use v6;

use NativeCall;

class GDBM does Associative {
    my class Datum is repr('CStruct') {
        has Str $.dptr is rw;
        has int $.dsize is rw;

    }
}
# vim: ft=perl6 expandtab sw=4
