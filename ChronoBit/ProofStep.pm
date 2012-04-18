package ChronoBit::ProofStep;
use Any::Moose;

with 'ChronoBit::StructClass';

use Data::ParseBinary;
use Digest::SHA;

use ChronoBit::SHA;
use ChronoBit::SHAState;
use ChronoBit::Bitcoin;
use ChronoBit::Util;
use ChronoBit::P2Pool;

sub struct {
	return Struct('step',
		var_int('type'), # 00 - normal step, 01 - reverse bytes
		If(sub { $_->ctx->{type} == 0 },
			Struct('normal',
				ChronoBit::SHAState->struct,
				var_bytes('prefix'),
				var_bytes('suffix'),
			),
		),
	);
}

has 'type' => (is => 'rw', default => 0);
has 'normal' => (is => 'rw', isa => 'HashRef', default => sub { {
	state => ChronoBit::SHAState->new(len => 0, state => ''),
	prefix => '',
	suffix => '',
} });

sub BUILD {
	my ($self) = @_;

	die 'unknown proofstep type ' . $self->type unless($self->type == 0 ||
		$self->type == 1);

	# make sure there's a state, even if it's empty
	unless(exists $self->normal->{state}) {
		$self->normal->{state} = ChronoBit::SHAState->new(len => 0, 
			state => '');
	}
}

# returns bytes for padding a state with the donation script
sub _donation_pad {
	my ($self, $state_len) = @_;

	if($state_len % 64 != 0) {
		my $pad = $ChronoBit::P2Pool::gentx_before_refhash;
		return substr($pad, 
			length($pad) - $state_len % 64
		);
	} else {
		return '';
	}
}

sub perform {
	my ($self, $buf) = @_;

	if($self->type == 0) { 
		my $sha;
		my $state = $self->normal->{state};
		if($state->{len} > 0) {
			# if our length is shorter than sha's block, pad with
			# p2pool's donation address
			$state->{extra_data} = $self->_donation_pad($state->{len});
			$sha = ChronoBit::SHA->new_from_state($state);
		} else {
			$sha = Digest::SHA->new(256);
		}

		$sha->add($self->normal->{prefix} || '');
		$sha->add($buf);
		$sha->add($self->normal->{suffix} || '');

		return $sha->digest;
	} elsif($self->type == 1) {
		return scalar reverse $buf;
	} else {
		die "unknown type";
	}
}

sub explain {
	my ($self, $buf) = @_;

	my $out = '';
	if($self->type == 0) {
		if($self->normal->{state}->{len} > 0) {
			$out .= sprintf("Begin with SHA state %s len %d data %s\n", 
				bin2hex($self->normal->{state}->{state}),
				$self->normal->{state}->{len},
				bin2hex($self->_donation_pad($self->normal->{state}->{len})),
			);
		}
		if($self->normal->{prefix}) {
			$out .= "Prepend bytes: " . bin2hex($self->normal->{prefix}) . "\n";
		}
		if($self->normal->{suffix}) {
			$out .= "Append bytes: " . bin2hex($self->normal->{suffix}) . "\n";
		}
		$out .= "Perform SHA-256 on the result. ";
	} elsif($self->type == 1) {
		$out = "Reverse all bytes. ";
	} else {
		die "unknown type";
	}

	my $res = $self->perform($buf);
	$out .= "Get " . bin2hex($res) . "\n";

	return ($res, $out);
}

1;
