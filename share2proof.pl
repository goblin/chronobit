#! /usr/bin/perl

# takes binary share data on stdin (as returned by /web/share_data/share...)
# and makes it into a proof (joining its parent's hash to this share's hash)

use strict;
use warnings;

use IO::All;
use YAML::Syck;

use ChronoBit::P2Pool;
use ChronoBit::Proof;
use ChronoBit::ProofStore;

my $data = io('-')->slurp;
my $share = share->parse($data);

my $proof = ChronoBit::Proof->new_from_share($share, '');
$proof->to($proof->perform);

my $cfg = LoadFile('chronobit.conf');

my $ps = ChronoBit::ProofStore->new(outdir =>
	$cfg->{proofs},
);

$ps->save($proof);
