package ChronoBit::SHA;
use Any::Moose;

extends 'Digest::SHA::PurePerl';
use Data::ParseBinary;
use ChronoBit::SHAState;

my $h_struct = Array(8, SBInt32());

sub new_from_state {
	my ($class, $state) = @_;

	my $ret = $class->new(256);
	$ret->{H} = $h_struct->parse($state->state);
	$ret->{lenll} = $state->len * 8;
	$ret->{blockcnt} = ($state->len * 8) % 512;
	$ret->{block} = $state->extra_data;

	return $ret;
}

sub get_state {
	my ($self) = @_;

	return ChronoBit::SHAState->new(
		state => $h_struct->build($self->{H}),
		len => int($self->{lenll} / 8),
		extra_data => $self->{block},
	);
}

1;
