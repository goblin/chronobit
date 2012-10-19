package ChronoBit::Proof;
use Any::Moose;

with 'ChronoBit::StructClass';

use Data::ParseBinary;
use Digest::SHA qw/sha256/;

use ChronoBit::Bitcoin;
use ChronoBit::P2Pool;
use ChronoBit::ProofStep;
use ChronoBit::SHAState;
use ChronoBit::Util;

sub struct {
	return Struct('proof',
		Bytes('from', 32),
		Bytes('to', 32),
		var_int('len'),
		Array(sub { $_->ctx->{len} }, ChronoBit::ProofStep->struct),
	);
}

has 'from' => (is => 'rw'); # binary
has 'to' => (is => 'rw'); # binary
has 'len' => (is => 'rw', default => 0);
has 'step' => (is => 'rw', isa => 'ArrayRef');

around 'new_from_binary' => sub {
	my ($meth, $class, @args) = @_;

	my $ret = $class->$meth(@args);

	# XXX hack: go through all our steps and bless them
	for(my $i = 0; $i < scalar @{$ret->step}; $i++) {
		bless $ret->step->[$i], 'ChronoBit::ProofStep';
		if($ret->step->[$i]->type == 0) {
			bless $ret->step->[$i]->{normal}->{state}, 'ChronoBit::SHAState';
		}
	}

	return $ret;
};

sub add_step {
	my ($self, $step) = @_;

	$self->len($self->len + 1);
	push @{$self->{step}}, $step;
}

sub perform {
	my ($self) = @_;

	my $cur = $self->from;
	for(my $i = 0; $i < $self->len; $i++) {
		$cur = $self->step->[$i]->perform($cur);
	}

	return $cur;
}

sub explain {
	my ($self) = @_;

	my $text = "Start with " . bin2hex($self->from) . "\n";
	my $buf = $self->from;
	for(my $i = 0; $i < $self->len; $i++) {
		my $cur;
		($buf, $cur) = $self->step->[$i]->explain($buf);
		$text .= $cur;
	}
	if($self->to eq $buf) {
		$text .= "Arrive at "; 
	} else {
		$text .= "PROOF INCORRECT, should get "
	}

	return $text . bin2hex($self->to) . "\n";
}

sub verify {
	my ($self) = @_;

	return $self->perform eq $self->to;
}

# helper function that adds proof steps from a merkle branch
sub _mrklbranch2proof {
	my ($class, $idx, $count, $branch, $proof, $extra_code) = @_;

	for(my $i = 0; $i < $count; $i++) {
		my $step = ChronoBit::ProofStep->new;

		my $which;
		if($idx % 2 == 0) {
			# we're on the left
			$which = 'suffix';
		} else {
			# we're on the right
			$which = 'prefix';
		}

		$step->normal->{$which} = $branch->[$i];
		$proof->add_step($step);
		$idx >>= 1;

		if($extra_code) {
			&$extra_code($proof);
		}
	}
}

# builds a proof from given hash (one set with set_hash rpc call)
# up to the coinbase (using aux_branch from aux PoW)
# $hash is expected to be binary
# $aux_pow is expected to be a parsed struct
sub new_aux2coinbase {
	my ($class, $hash, $aux_pow) = @_;

	my $raw_coinbase = $aux_pow->{coinbase_txn}->{tx_in}->[0]->{signature_script};

	my $mm_coinbase = mm_coinbase->parse(
		substr($raw_coinbase, index($raw_coinbase, "\xfa\xbemm"), 44));

	my $proof = $class->new(
		from => $hash, 
		to => scalar reverse $mm_coinbase->{block_hash}
	);
	
	$class->_mrklbranch2proof($aux_pow->{index}, 
		$aux_pow->{aux_branch_count}, $aux_pow->{aux_branch}, $proof);

	# one last sha256 (remember they get double-sha256ed?)
	$proof->add_step(ChronoBit::ProofStep->new);

	return $proof;
}

# builds a proof from given coinbase up to the generation transaction's hash
# takes a parsed gentx as input
sub new_coinbase2gentx {
	my ($class, $gentx) = @_;

	my $raw_coinbase = $gentx->{tx_in}->[0]->{signature_script};

	my $src_hash = mm_coinbase->parse(
		substr($raw_coinbase, index($raw_coinbase, "\xfa\xbemm"), 44))->{block_hash};
	my $gentx_bin = tx->build($gentx);

	my $proof = $class->new(
		from => $src_hash,
		to => sha256(sha256($gentx_bin)),
	);

	# simply find the latest occurence of coinbase in the gentx.
	# the latter one we find, the more we can compress in front
	my $loc = -1;
	my $newloc;
	my $revfound = 0;
	while(($newloc = index($gentx_bin, $src_hash, $loc + 1)) >= 0) {
		$loc = $newloc;
	}
	# maybe a reverse?
	while(($newloc = index($gentx_bin, scalar reverse $src_hash, $loc + 1)) 
			> $loc) {
		$loc = $newloc;
		$revfound = 1;
	}
	die 'no hash in gentx?' if($loc < 0);

	if($revfound) {
		$proof->add_step(ChronoBit::ProofStep->new(type => 1));
	}

	$proof->add_step(ChronoBit::ProofStep->new(normal => {
		prefix => substr($gentx_bin, 0, $loc),
		suffix => substr($gentx_bin, $loc + 32),
	}));

	# one last sha256
	$proof->add_step(ChronoBit::ProofStep->new);

	return $proof;
}

# builds a proof from given generation transaction's hash up to the block's
# merkle root.
# takes a parsed aux PoW as input
sub new_gentx2mrklroot {
	my ($class, $aux_pow) = @_;

	my $proof = $class->new(
		from => sha256(sha256(tx->build($aux_pow->{coinbase_txn}))),
		to => $aux_pow->{parent_block}->{merkle_root},
	);

	my $ml = $aux_pow->{merkle_link};
	$class->_mrklbranch2proof($ml->{index}, $ml->{branch_count},
		$ml->{branch}, $proof, sub { 
			# after each step, add another round of sha256 - merkle tree
			# use double sha256ing, whereas aux_branch only one
			$_[0]->add_step(ChronoBit::ProofStep->new);
		} 
	);

	return $proof;
}

# builds a proof for a block (from merkle root)
sub new_mrklroot2block {
	my ($class, $block_header) = @_;

	my $hdr_bin = block_header->build($block_header);

	my $proof = $class->new(
		from => $block_header->{merkle_root},
		to => sha256(sha256($hdr_bin)),
	);

	$proof->add_step(ChronoBit::ProofStep->new(normal => {
		prefix => substr($hdr_bin, 0, 36),
		suffix => substr($hdr_bin, 68)
	}));

	$proof->add_step(ChronoBit::ProofStep->new);

	return $proof;
}

# builds a new proof by merging existing ones (keeps refs to existing
# steps, however, so don't mess around with steps)
sub new_merged {
	my ($class, @proofs) = @_;

	die "no proofs given" unless @proofs > 0;

	my $proof = $class->new();
	my $first = 1;

	foreach my $p (@proofs) {
		unless($first) {
			if($proof->to eq scalar reverse $p->from) {
				$proof->add_step(ChronoBit::ProofStep->new(type => 1));
			} else {
				die "proofs don't match up" unless($proof->to eq $p->from);
			}
		}

		if($first) {
			$proof->from($p->from);
			$first = 0;
		} 
		$proof->to($p->to);

		foreach my $s  (@{$p->step}) {
			$proof->add_step($s);
		}
	}

	return $proof;
}

# creates a new hash from PoW
sub new_from_pow {
	my ($class, $hash, $pow) = @_;

	my @proofs = (
		ChronoBit::Proof->new_aux2coinbase($hash, $pow),
		ChronoBit::Proof->new_coinbase2gentx($pow->{coinbase_txn}),
		ChronoBit::Proof->new_gentx2mrklroot($pow),
		ChronoBit::Proof->new_mrklroot2block($pow->{parent_block}),
	);

	return ChronoBit::Proof->new_merged(@proofs);
}

# builds a proof from a p2pool share (proof from previous share's hash 
# to this share's hash)
sub new_from_share {
	my ($class, $share, $share_hash) = @_;

	die "unimplemented share type" unless($share->{type} == 4);

	my $proof = $class->new(
		from => $share->{contents}->{common}->{share_info}->{share_data}->
			{previous_share_hash},
		to => $share_hash,
	);

	# first convert our previous share's hash into share_info.
	# that's needed for the ref_hash later.
	# we do it by building the entire share_info and then removing our
	# prev share's hash from the (8,40) location (first 8 bytes is network's
	# magic)
	my $ref_type = ref_type->build({ share_info =>
		$share->{contents}->{common}->{share_info}
	});
	$proof->add_step(ChronoBit::ProofStep->new(normal => {
		prefix => substr($ref_type, 0, 8),
		suffix => substr($ref_type, 40),
	}));
	
	# hash it again
	$proof->add_step(ChronoBit::ProofStep->new);

	# now we have ref_hash in our buffer (just need to add 4x00 to it)
	# so we can append it to our gentx's state
	my $hash_link = $share->{contents}->{common}->{hash_link};
	$proof->add_step(ChronoBit::ProofStep->new(normal => {
		state => ChronoBit::SHAState->new(len => $hash_link->{length},
			state => $hash_link->{state}),
		suffix => "\0"x4,
		prefix => '',
	}));

	# hash it again
	$proof->add_step(ChronoBit::ProofStep->new);

	# and now that we have gentx's hash in buffer, we can build up from
	# it up to merkle root
	$class->_mrklbranch2proof(0, # gentx's index is always 0
		$share->{contents}->{merkle_link}->{length},
		$share->{contents}->{merkle_link}->{branch}, 
		$proof, sub { 
			# after each step, add another round of sha256 - merkle tree
			# use double sha256ing, whereas aux_branch only one
			$_[0]->add_step(ChronoBit::ProofStep->new);
		} 
	);

	# now that we have merkle root in buffer, we can build our share's
	# hash from it
	my $sbh = $share->{contents}->{common}->{min_header};
	my $block = block_header->build({
		version => $sbh->{version}, # damn, these HAD to be incompatible...
			# p2pool's is a var_int, bitcoin's is a uint32
		prev_block => $sbh->{previous_block},
		merkle_root => "\x0"x32, # we'll fill it up later
		timestamp => $sbh->{timestamp},
		bits => $sbh->{bits},
		nonce => $sbh->{nonce},
	});
	$proof->add_step(ChronoBit::ProofStep->new(normal => {
		prefix => substr($block, 0, 36),
		suffix => substr($block, 68),
	}));
	
	# final sha and we have our share's/block's hash
	$proof->add_step(ChronoBit::ProofStep->new);

	return $proof;
}

1;
