use v6;

use NativeCall;

class GDBM does Associative {
    enum OpenMode ( Reader => 0, Writer => 1, Create => 2, New => 3);
    my constant OpenMask = 7;
    enum OpenOptions ( Fast => 0x010, Sync => 0x020, NoLock => 0x040, NoMMap => 0x080, CloExec => 0x100);
    
    enum StoreOptions ( Insert => 0, Replace => 1 );

    my class Datum is repr('CStruct') {
        has Str $.dptr is rw;
        has int $.dsize is rw;
    }

    class X::Fatal is Exception {
        has Str $.message;
    }

    sub fail(Str $message) {
        X::Fatal.new(:$message).throw;
    }

    my class File is repr('CPointer') {
        sub gdbm_open(Str $file, int $bs, int $flags, int $mode, &fatal ( Str $message)) returns File is native('libgdbm') { * }

    }
}
# vim: ft=perl6 expandtab sw=4
