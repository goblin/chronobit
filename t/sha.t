use strict;
use warnings;

use Test::More;

use ChronoBit::Util;

BEGIN { use_ok('ChronoBit::SHA'); }
BEGIN { use_ok('ChronoBit::SHAState'); }

my $test_msg1 = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum';

my $sha = ChronoBit::SHA->new(256);
$sha->add($test_msg1);
is($sha->digest, hex2bin('bfe8ee358697cbd746acd482c37891dca980bd0401d596dabf5551857b6b53a2'));

$sha = ChronoBit::SHA->new(256);
$sha->add(substr $test_msg1, 0, 133);
$sha->add(substr $test_msg1, 133);
is($sha->digest, hex2bin('bfe8ee358697cbd746acd482c37891dca980bd0401d596dabf5551857b6b53a2'));

$sha = ChronoBit::SHA->new(256);
$sha->add(substr $test_msg1, 0, 133);
my $state = $sha->get_state;
undef $sha;
$sha = ChronoBit::SHA->new_from_state($state);
$sha->add(substr $test_msg1, 133);
is($sha->digest, hex2bin('bfe8ee358697cbd746acd482c37891dca980bd0401d596dabf5551857b6b53a2'));

done_testing;
