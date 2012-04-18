use strict;
use warnings;

use Test::More;

use ChronoBit::Util;
BEGIN { use_ok('ChronoBit::SHA'); }
BEGIN { use_ok('ChronoBit::SHAState'); }

# OK, here's what p2pool gives:
my $state = ChronoBit::SHAState->new(
	state => hex2bin(
		'a1405e36d6b21fe6287e18765b5140590b7e34d6f52d8fbcd1d56dab1dcf9ad5'),
	len => 7494,
	extra_data => hex2bin('000000002120'),
);
my $sha = ChronoBit::SHA->new_from_state($state);
$sha->add(hex2bin(
	'0b08c84e31867549f9189cb9c696d61916d3ffa9ac8fec4a1812deb7f10dac4200000000'
));
is(bin2hex($sha->digest), 
	'58ba6c61a3700085304d1cb5461a6237e43730745d04cf55f4a9b33da6132ac9');

done_testing;
