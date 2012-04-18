package ChronoBit::Bitcoin::VarIntAdapter;

use strict;
use warnings;

use Data::ParseBinary;

our @ISA = qw/Data::ParseBinary::Adapter/;

sub _encode {
	my ($self, $value) = @_;

	my $ret = { value => $value, b1 => $value };
	if($value >= 0xfd) {
		if($value <= 0xffff) {
			$ret->{b1} = 0xfd;
		} elsif($value <= 0xffffffff) {
			$ret->{b1} = 0xfe;
		} else {
			$ret->{b1} = 0xff;
		}
	}

	return $ret;
}

sub _decode {
	my ($self, $value) = @_;

	return $value->{value};
}

sub var_int {
	return ChronoBit::Bitcoin::VarIntAdapter->create(Struct($_[0],
		Byte("b1"),
		IfThenElse("value", sub { $_->ctx->{b1} < 0xfd },
			Value('uint8_t value', sub { $_->ctx->{b1} }),
			IfThenElse('>8 value', sub { $_->ctx->{b1} == 0xfd },
				ULInt16('uint16_t value'),
				IfThenElse('>16 value', sub { $_->ctx->{b1} == 0xfe },
					ULInt32('uint32_t value'),
					ULInt64('uint64_t value')
				)
			)
		)
	))
}

1;

