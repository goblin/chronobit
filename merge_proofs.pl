#! /usr/bin/perl

# merges all proofs given as args

use strict;
use warnings;

use IO::All;
use YAML::Syck;

use ChronoBit::Proof;
use ChronoBit::ProofFile;
use ChronoBit::ProofStore;

my @proof_file = map { 
	ChronoBit::ProofFile->struct->parse(scalar io($_)->slurp);
} @ARGV;
my @proof = map { 
	# XXX: haxx
	ChronoBit::Proof->new_from_binary(
		ChronoBit::Proof->struct->build($_->{proof})
	)
} @proof_file;

my $newproof = ChronoBit::Proof->new_merged(@proof);

my $cfg = LoadFile('chronobit.conf');

my $ps = ChronoBit::ProofStore->new(outdir =>
	$cfg->{proofs},
);

my $filename = $ps->save($newproof, $proof_file[0]->{data}); # TODO: keep timestamp too
printf "Saved proof to $filename\n";
