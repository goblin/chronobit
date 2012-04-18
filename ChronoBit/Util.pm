package ChronoBit::Util;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw/hex2bin bin2hex/;

sub hex2bin {
	return pack('(H2)*', unpack('(a2)*', $_[0]));
}

sub bin2hex {
	return join('', unpack('(H2)*', $_[0]));
}

1;
