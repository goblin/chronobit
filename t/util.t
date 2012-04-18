use strict;
use warnings;

use Test::More;

BEGIN { use_ok('ChronoBit::Util'); }

my $test_msg1 = 'Lorem ipsum dolor sit amet';
my $msg1_hex = '4c6f72656d20697073756d20646f6c6f722073697420616d6574';

is(hex2bin($msg1_hex), $test_msg1);
is(bin2hex($test_msg1), $msg1_hex);

done_testing;
