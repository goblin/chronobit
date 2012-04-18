#! /usr/bin/perl

# this script takes 2 filenames as arguments: first file is a long proof
# (made from getauxblock response), second file is a short proof (made from
# p2pool share_data). Both proofs must arrive at the same hash (of p2pool
# share).
# the script will merge the 2 proofs to create a smaller proof for the original
# hash (it'll output a shorter version of the first file).

use strict;
use warnings;

use IO::All;
use YAML::Syck;

use ChronoBit::Proof;
use ChronoBit::ProofFile;
use ChronoBit::ProofStore;
use ChronoBit::ProofStep;

my @proof_file = map { 
	ChronoBit::ProofFile->struct->parse(scalar io($_)->slurp);
} @ARGV;
my @proof = map { 
	# XXX: haxx
	ChronoBit::Proof->new_from_binary(
		ChronoBit::Proof->struct->build($_->{proof})
	)
} @proof_file;
my $newproof = ChronoBit::Proof->new(
	from => $proof[0]->from,
	to => $proof[0]->to,
);

die "wrong proofs" unless($proof[0]->to eq $proof[1]->to);

# first, copy all large proof's steps up to byte reversal.
# Byte reversal gets us data that goes in the coinbase.
my $ok = 0;
for(my $i = 0; my $step = $proof[0]->step->[$i]; $i++) {
	$newproof->add_step($step);
	if($step->type == 1) {
		$ok = 1;
		last;
	}
}
die "no byte reversal?" unless $ok;

# compute that coinbase
my $coinbase = $newproof->perform;

# this is the first step of shorter proof:
my $step1 = $proof[1]->step->[0]->normal;

# find me the position at which our coinbase starts in step1's suffix:
die "wtf" unless(length($coinbase) == 32);
my $pos = index($step1->{suffix}, $coinbase);

# now create a step that'll put that coinbase in shorter proof's perspective
$newproof->add_step(ChronoBit::ProofStep->new(normal => {
	prefix => $step1->{prefix} . $proof[1]->from . substr($step1->{suffix},
		0, $pos),
	suffix => substr($step1->{suffix}, $pos + 32),
}));

# and copy all the remaining steps
for(my $i = 1; $i < $proof[1]->len; $i++) {
	$newproof->add_step($proof[1]->step->[$i]);
}

my $cfg = LoadFile('chronobit.conf');

my $ps = ChronoBit::ProofStore->new(outdir =>
	$cfg->{proofs},
);

$ps->save($newproof, $proof_file[0]->{data}); # TODO: keep timestamp too
