#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 4;

BEGIN {
    use_ok('Number::Phone::IN')           || print "Bail out!";
    use_ok('Number::Phone::IN::Operator') || print "Bail out!";
    use_ok('Number::Phone::IN::Zone')     || print "Bail out!";
    use_ok('Number::Phone::IN::Chart')    || print "Bail out!";
}
diag( "Testing Number::Phone::IN $Number::Phone::IN::VERSION, Perl $], $^X" );
