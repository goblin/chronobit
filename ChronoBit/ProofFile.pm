package ChronoBit::ProofFile;
use Any::Moose;

with 'ChronoBit::StructClass';

use Data::ParseBinary;
use ChronoBit::Bitcoin;
use ChronoBit::Proof;

sub struct {
	return Struct($_[0], 
		Magic("\xd4\x97\xcf\x52"),
		var_str('data'),
		var_int('timestamp'),
		ULInt32('timestamp_usec'),
		ChronoBit::Proof->struct('proof'),
	);
}

1;
