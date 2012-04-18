#! /usr/bin/perl

use strict;
use warnings;

use IO::All;
use Digest::SHA qw/sha256/;
use Data::ParseBinary;

use ChronoBit::Bitcoin;
use ChronoBit::ProofFile;
use ChronoBit::Proof;
use ChronoBit::Util;

my $data = io('-')->slurp;
my $proof_file = ChronoBit::ProofFile->struct->parse($data);

# XXX: haxx
my $proof = ChronoBit::Proof->new_from_binary(
	ChronoBit::Proof->struct->build($proof_file->{proof})
);

print $proof->explain if $ARGV[0];
printf "proof from %s\n        to %s\n", bin2hex($proof->from), 
	bin2hex($proof->to);
print 'data: <' . $proof_file->{data} . ">\n";
print '(data ' . ((sha256($proof_file->{data}) eq $proof->from) ? 'does' : 
	'DOES NOT') . " map to proof's start)\n";
print '(data+timestamp ' . ((sha256($proof_file->{data} . 
		var_int->build($proof_file->{timestamp}) . 
		ULInt32->build($proof_file->{timestamp_usec}
	)) eq $proof->from) ? 'does' : 'DOES NOT') . " map to proof's start)\n";
printf "claims to be made on %s %06d usec GMT\n",
	scalar(gmtime($proof_file->{timestamp})),
	$proof_file->{timestamp_usec};

my $res = $proof->verify;
print $res ? "proof ok\n" : "PROOF INVALID\n";

exit $res;

