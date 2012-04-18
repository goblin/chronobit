use strict;
use warnings;

use Test::More;

use JSON::XS;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($INFO);

BEGIN { use_ok('ChronoBit::JSONRPC'); }

my $j = ChronoBit::JSONRPC->new(cfg => { chainid => 2, proofs => 'foo' });
is($j->curhash, undef);

is_deeply($j->getauxblock(), { chainid => 2, hash => '00'x32, target => 'p2pool' });
is_deeply($j->set_hash('1a'.'31'x31), JSON::XS::true);
is($j->curhash, '1a'.'31'x31);
is_deeply($j->getauxblock(), { chainid => 2, hash => ('31'x31 . '1a'), target => 'p2pool' });

# TODO: test some PoWs
# is_deeply($j->getauxblock('31'x31 . '1a', $

is_deeply($j->unset_hash(), JSON::XS::true);
is($j->curhash, undef);
is_deeply($j->getauxblock(), { chainid => 2, hash => '00'x32, target => 'p2pool' });

done_testing;
