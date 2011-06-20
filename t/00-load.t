#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Queue::Base::Redis' ) || print "Bail out!\n";
}

diag( "Testing Queue::Base::Redis $Queue::Base::Redis::VERSION, Perl $], $^X" );
