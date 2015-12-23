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

        multi method new(Str $val) {
            my int $dsize = $val.encode.bytes;
            self.new(dptr => $val, :$dsize);
        }

        method Str() {
            $!dptr;
        }
    }

    class X::Fatal is Exception {
        has Str $.message;
    }

    sub fail(Str $message) {
        X::Fatal.new(:$message).throw;
    }

    my class File is repr('CPointer') {
        sub gdbm_open(Str $file, int $bs, int $flags, int $mode, &fatal ( Str $message)) returns File is native('gdbm',v4) { * }

        multi method new(Str() :$file, Int :$block-size = 512, Int() :$flags = Create +| Sync, Int :$mode = 0o644) returns File {
            gdbm_open($file, $block-size, $flags, $mode, &fail);

        }

        sub gdbm_close(File $f) is native('gdbm',v4) { * };

        method close() {
            gdbm_close(self);
        }

        sub gdbm_store(File $f, Datum $k, Datum $v, int $m) returns int is native('gdbm',v4) { * }

        multi method store(Datum $k, Datum $v, StoreOptions $flag = Replace) returns Int {
            gdbm_store(self, $k, $v, $flag.Int);
        }

        multi method store(Str $k, Str $v, StoreOptions $flag = Replace) returns Int {
            self.store(Datum.new($k), Datum.new($v), $flag);
        }

        sub gdbm_fetch(File $f, Datum $k) returns Datum is native('gdbm',v4) { * }

        multi method fetch(Datum $k) returns Str {
            my $ret = gdbm_fetch(self, $k);
            $ret.Str;
        }

        multi method fetch(Str $k) returns Str {
            self.fetch(Datum.new($k));
        }

        sub gdbm_delete(File $f, Datum $k) returns int is native('gdbm',v4) { * }
        multi method delete(Datum $k) returns Int {
            gdbm_delete(self, $k);
        }

        multi method delete(Str $k) returns Int {
            self.delete(Datum.new($k));
        }

        # For the methods of these we'll just return the Datum as
        # we'll only be passing to next anyway

        sub gdbm_firstkey(File $f) returns Datum is native('gdbm',v4) { * }

        multi method first-key() returns Datum {
            gdbm_firstkey(self);
        }


        sub gdbm_nextkey(File $f, Datum $prev) returns Datum is native('gdbm',v4) { * }

        multi method next-key(Datum $prev) returns Datum {
            gdbm_nextkey(self, $prev);
        }

        sub gdbm_reorganize (File $f) returns int is native('gdbm',v4) { * }

        method reorganize() returns Int {
            gdbm_reorganize(self);
        }

        sub gdbm_sync(File $f) is native('gdbm',v4) { * }

        method sync() {
            gdbm_sync(self);
        }

        sub gdbm_exists(File $f, Datum $k) returns int is native('gdbm',v4) { * }
        multi method exists(Datum $k) returns Bool {
            my Int $rc = gdbm_exists(self, $k);
            return Bool($rc);
        }

        multi method exists(Str $k) returns Bool {
            self.exists(Datum.new($k));
        }

        sub gdbm_count(File $f, CArray[uint64] $pcount) returns int is native('gdbm',v4) { * }

        method count() returns Int {
            my CArray[uint64] $pcount = CArray[uint64].new;
            $pcount[0] = 0;
            gdbm_count(self, $pcount);
            return Int($pcount[0]);
        }

    }

    has File $!file handles <fetch store exists delete sync close>;

    multi method new(Str() $filename) {
        my $file = File.new(file => $filename);
        self.new(:$file);
    }

    multi submethod BUILD(File :$!file ) {
    }
}
# vim: ft=perl6 expandtab sw=4
