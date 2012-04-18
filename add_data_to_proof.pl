#! /usr/bin/perl

# takes a proof (given as argument) and adds data from stdin as the
# proof's data. Doesn't validate anything.

use strict;
use warnings;

use IO::All;
use YAML::Syck;

use ChronoBit::Proof;
use ChronoBit::ProofFile;
use ChronoBit::ProofStore;

print "Loading your proof, wait...\n";
my $proof_file = ChronoBit::ProofFile->struct->parse(
	scalar io($ARGV[0])->slurp);

# XXX: haxx
my $proof = ChronoBit::Proof->new_from_binary(
	ChronoBit::Proof->struct->build($proof_file->{proof})
);

$| = 1;
print "Go ahead and type your data\n";
my $data = io('-')->slurp;
print "Thanks, please wait till I save the proof...\n";

my $cfg = LoadFile('chronobit.conf');

my $ps = ChronoBit::ProofStore->new(outdir =>
	$cfg->{proofs},
);

my $filename = $ps->save($proof, $data); 
printf "Proof saved to $filename\n";
