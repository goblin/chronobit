package ChronoBit::SHAState;
use Any::Moose;

with 'ChronoBit::StructClass';

use Data::ParseBinary;
use ChronoBit::Bitcoin;

sub struct {
	return Struct('state',
		var_int('len'), # this is the digest length up to this state
		If(sub { $_->ctx->{len} > 0 },
			Bytes('state', 32),
		),
		# we purposefully don't include extra_data as it's always 0
		# -- any real extra_data bytes can be in ProofStep's prefix.
	);
}

has 'state' => (is => 'rw');
has 'len' => (is => 'rw');
has 'extra_data' => (is => 'rw');

1;
