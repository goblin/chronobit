package ChronoBit::Bitcoin::VarStrAdapter;

use strict;
use warnings;

use Data::ParseBinary;
use ChronoBit::Bitcoin::VarIntAdapter;

our @ISA = qw/Data::ParseBinary::Adapter/;

sub _encode {
	my ($self, $value) = @_;

	return {
		length => length($value),
		value => $value,
	};
}

sub _decode {
	my ($self, $value) = @_;

	return $value->{value};
}

sub var_str {
	return ChronoBit::Bitcoin::VarStrAdapter->create(Struct($_[0],
		ChronoBit::Bitcoin::VarIntAdapter::var_int('length'),
		String('value', sub { $_->ctx->{length} }, encoding => 'ascii'),
	))
}

sub var_bytes {
	return ChronoBit::Bitcoin::VarStrAdapter->create(Struct($_[0],
		ChronoBit::Bitcoin::VarIntAdapter::var_int('length'),
		Field('value', sub { $_->ctx->{length} }),
	))
}

1;
