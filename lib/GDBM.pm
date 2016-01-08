use v6;

use NativeCall;
use NativeHelpers::Array;

class GDBM does Associative {
    enum OpenMode ( Reader => 0, Writer => 1, Create => 2, New => 3);
    my constant OpenMask = 7;
    enum OpenOptions ( Fast => 0x010, Sync => 0x020, NoLock => 0x040, NoMMap => 0x080, CloExec => 0x100);
    
    enum StoreOptions ( Insert => 0, Replace => 1 );

    class Datum is repr('CStruct') is rw {
        has CArray           $.dptr  is rw;
        has uint32           $.dsize is rw;

        multi method new(Str() $val) {
            my $buf = $val.encode; 
            my uint32 $dsize = $buf.bytes;
            my $a = self.new(dptr => $buf, :$dsize);
            $a.dsize = $dsize;
            return $a;
        }

        submethod BUILD(:$dptr, :$dsize) {

            my $a:= copy-buf-to-carray(Buf.new($dptr.list));
            $!dptr := $a;
            $!dsize = $dsize;
        }

        method Str() {
            copy-carray-to-buf($!dptr, $!dsize).decode;
        }
    }

    class X::Fatal is Exception {
        has Str $.message;
    }

    sub fail(Str $message ) {
        explicitly-manage($message);
        X::Fatal.new(:$message).throw;
    }

    my class File is repr('CPointer') {
        sub gdbm_open(Str $file, uint32 $bs, uint32 $flags, uint32 $mode, &fatal ( Str $message )) returns File is native('gdbm',v4) { * }

        multi method new(Str() :$file, Int :$block-size = 512, Int() :$flags = Create +| Sync +| NoMMap, Int :$mode = 0o644) returns File {
            explicitly-manage($file);
            gdbm_open($file, $block-size, $flags, $mode, &fail);

        }

        sub gdbm_close(File $f) is native('gdbm',v4) { * };

        method close() {
            gdbm_close(self);
        }

        sub gdbm_store(File:D $f, Datum $k, Datum $v, uint32 $m) returns int32 is native('gdbm',v4) { * }

        multi method store(Datum:D $k, Datum:D $v, StoreOptions $flag = Replace) returns Int {
            say "store { $k.perl } => { $v.perl }";
            gdbm_store(self, $k, $v, $flag.Int);
        }

        multi method store(Str:D $k, Str:D $v, StoreOptions $flag = Replace) returns Int {
            say "store $k => $v";
            my $key = Datum.new($k);
            my $val = Datum.new($v);
            self.store($key, $val, $flag);
        }

        sub gdbm_fetch(File $f, Datum $k) returns Datum is native('gdbm',v4) { * }

        multi method fetch(Datum $k) returns Str {
            my $ret = gdbm_fetch(self, $k);
            $ret.Str;
        }

        multi method fetch(Str $k) returns Str {
            self.fetch(Datum.new($k));
        }

        sub gdbm_delete(File $f, Datum $k) returns int32 is native('gdbm',v4) { * }
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

        sub gdbm_reorganize (File $f) returns int32 is native('gdbm',v4) { * }

        method reorganize() returns Int {
            gdbm_reorganize(self);
        }

        sub gdbm_sync(File $f) is native('gdbm',v4) { * }

        method sync() {
            gdbm_sync(self);
        }

        sub gdbm_exists(File $f, Datum $k) returns int32 is native('gdbm',v4) { * }
        multi method exists(Datum $k) returns Bool {
            my Int $rc = gdbm_exists(self, $k);
            return Bool($rc);
        }

        multi method exists(Str $k) returns Bool {
            self.exists(Datum.new($k));
        }

        sub gdbm_count(File $f, CArray[uint64] $pcount) returns int32 is native('gdbm',v4) { * }

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

    multi method EXISTS-KEY (::?CLASS:D: $key) {
        self.exists($key);
    }

    multi method DELETE-KEY (::?CLASS:D: $key) {
        self.delete($key);
    }

    multi method ASSIGN-KEY (::?CLASS:D: Str $key, Str $new) {
        self.store($key, $new, Replace);
    }

    multi method AT-KEY (::?CLASS:D $self: $key) {
        Proxy.new(
            FETCH   =>  method () {
                $self.fetch($key);
            },
            STORE   => method ($val) {
                self.store($key, $val, Replace);
            }
        );
    }
}
# vim: ft=perl6 expandtab sw=4
