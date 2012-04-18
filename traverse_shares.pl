#! /usr/bin/perl

# $ ./traverse_shares.pl [<from>] <to>

# goes backwards from a later share's hash <from> down to an earlier 
# share's hash <to>
#
# creates a proof from <to> to <from>.
#
# if <from> is not given, defaults to current best share hash.
# byte order doesn't matter, script will reverse as necessary

use strict;
use warnings;

use YAML::Syck;
use JSON::XS;
use LWP::UserAgent;

use ChronoBit::P2Pool;
use ChronoBit::Proof;
use ChronoBit::ProofStore;
use ChronoBit::Util;

$| = 1;
my $cfg = LoadFile('chronobit.conf');
my $addr = $cfg->{p2pool};
my $ua = LWP::UserAgent->new;
$ua->timeout(5);
my $json = JSON::XS->new->allow_nonref;

my $cnt = 0;
sub get {
	my $what = shift;

	print "[$cnt] getting $what...\n";
	my $res = $ua->get("$addr/$what");
	if($res->is_success) {
		return $res->decoded_content;
	} else {
		die $res->status_line;
	}
}

die "need argument" unless $ARGV[0];

my $from;
my $target;
if($ARGV[1]) {
	$from = $ARGV[0];
	# reverse if needed
	if(substr($from, 0, 8) ne '00000000') {
		$from = bin2hex(scalar reverse hex2bin($from));
	}
	$target = $ARGV[1];
} else {
	$from = $json->decode(get("web/best_share_hash"));
	$target = $ARGV[0];
}

$target = hex2bin(lc $target);

sub target {
	my $what = shift;
	
	return ($what eq $target) || ($what eq (scalar reverse $target));
}

my $cur_hash = $from;
my $proof;

while(!target(hex2bin($cur_hash))) {
	my $share_json = $json->decode(get("web/share/$cur_hash"));

	my $share = share->parse(get("web/share_data/$cur_hash"));
	my $cur_proof = ChronoBit::Proof->new_from_share($share, 
		scalar reverse hex2bin($cur_hash)
	);

	if(defined $proof) {
#		printf "merging proof from %s to %s\n", bin2hex($cur_proof->from), 
#			bin2hex($cur_proof->to);
#		printf "         with from %s to %s\n", bin2hex($proof->from), 
#			bin2hex($proof->to);
		$proof = ChronoBit::Proof->new_merged($cur_proof, $proof);
	} else {
		$proof = $cur_proof;
	}

	$cur_hash = $share_json->{parent};
	$cnt++;
}

my $ps = ChronoBit::ProofStore->new(outdir => $cfg->{proofs});
my $filename = $ps->save($proof); 

printf "Saved proof to $filename\n";
