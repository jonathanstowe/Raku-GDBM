use v6.c;

=begin pod

=head1 NAME

GDBM - Gnu DBM binding

=head1 SYMOPSIS

=begin code

use GDBM;

my $data = GDBM.new('somefile.db');

$data<foo> = 'bar';

say $data<foo>:exists;

$data.close;

# Then in some time later, possibly in another program

$data = GDBM.new('somefile.db');

say $data<foo>;

$data.close;

=end code

=head1 DESCRIPTION

The L<GNU DBM|http://www.gnu.org.ua/software/gdbm/> stores key/value
pairs in a hashed database file. Its implementation allows for keys
and values of arbitrary length (compared to fairly frugal limits on
some earlier implementations.)

This module allows for the data to be transparently managed as if it
were in an normal Associative container such as a Hash.  The only limitation
currently is that both key and value must be strings (or can be meaningfully
stringified,) so e.g. structured data will need to be serialised to some
format that can be represented as a string.  However it can be used for
persistence or caching if this doesn't need to be shared by processes
on different machines.

=head1 METHODS

=end pod

use NativeCall;

class GDBM does Associative {

    my constant HELPER = %?RESOURCES<libraries/gdbmhelper>.Str;

    enum OpenMode ( Reader => 0, Writer => 1, Create => 2, New => 3);
    my constant OpenMask = 7;
    enum OpenOptions ( Fast => 0x010, Sync => 0x020, NoLock => 0x040, NoMMap => 0x080, CloExec => 0x100);

    enum StoreOptions ( Insert => 0, Replace => 1 );

    class X::Fatal is Exception {
        has Str $.message;
    }

    sub fail(Str $message ) {
        explicitly-manage($message);
        X::Fatal.new(:$message).throw;
    }

    my class File is repr('CPointer') {
        sub p_gdbm_open(Str $file, uint32 $bs, uint32 $flags, uint32 $mode, &fatal ( Str $message )) returns File is native(HELPER) { * }

        multi method new(Str() :$file!, Int :$block-size = 512, Int() :$flags = Create +| Sync +| NoMMap, Int :$mode = 0o644) returns File {
            explicitly-manage($file);
            p_gdbm_open($file, $block-size, $flags, $mode, &fail);

        }

        sub p_gdbm_close(File:D $f) is native(HELPER) { * };

        method close() {
            p_gdbm_close(self);
        }

        sub p_gdbm_store(File:D $f, Str $k, Str $v, uint32 $m) returns int32 is native(HELPER) { * }

        multi method store(Str:D $k, Str:D $v, StoreOptions $flag = Replace) returns Int {
            p_gdbm_store(self, $k, $v, $flag.Int);
        }

        sub p_gdbm_fetch(File:D $f, Str $k) returns Str is native(HELPER) { * }

        multi method fetch(Str $k) returns Str {
            p_gdbm_fetch(self, $k);
        }

        sub p_gdbm_delete(File:D $f, Str $k) returns int32 is native(HELPER) { * }

        multi method delete(Str $k) returns Int {
            p_gdbm_delete(self, $k);
        }

        # For the methods of these we'll just return the Datum as
        # we'll only be passing to next anyway

        sub p_gdbm_firstkey(File:D $f) returns Str is native(HELPER) { * }

        multi method first-key() returns Str {
            p_gdbm_firstkey(self);
        }


        sub p_gdbm_nextkey(File:D $f, Str $prev) returns Str is native(HELPER) { * }

        multi method next-key(Str $prev) returns Str {
            p_gdbm_nextkey(self, $prev);
        }

        sub p_gdbm_reorganize (File:D $f) returns int32 is native(HELPER) { * }

        method reorganize() returns Int {
            p_gdbm_reorganize(self);
        }

        sub p_gdbm_sync(File:D $f) is native(HELPER) { * }

        method sync() {
            p_gdbm_sync(self);
        }

        sub p_gdbm_exists(File:D $f, Str $k) returns int32 is native(HELPER) { * }
        multi method exists(Str $k) returns Bool {
            my Int $rc = p_gdbm_exists(self, $k);
            return Bool($rc);
        }
    }

    has File $!file handles <fetch store exists delete sync close>;

    has Str $.filename is required;

    multi method new(Str() $filename) {
        self.new(:$filename);
    }

    multi method BUILD(:$!filename!, |c) {
        $!file = File.new(file => $!filename, |c);
    }

    multi submethod BUILD(File :$!file! ) {
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

    method keys(::?CLASS:D: --> Seq) {
        gather {
            my $key = $!file.first-key;
            while $key.defined {
                take $key;
                $key = $!file.next-key($key);
            }
        }
    }

    method kv(::?CLASS:D: --> Seq) {
        gather {
            for self.keys -> $key {
                take $key;
                take self.fetch($key) ;
            }
        }
    }

    method pairs(::?CLASS:D: --> Seq) {
        gather {
            for self.kv -> $k, $v {
                take $k => $v;
            }
        }
    }

    # Copied straight from Hash
    method perl(::?CLASS:D: --> Str ) {
        '{' ~ self.pairs.sort.map({.perl}).join(', ') ~ '}'
    }
}

# vim: ft=perl6 expandtab sw=4
