package ChronoBit::P2Pool;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw/small_block_header share_data share_info hash_link 
	share_common share1a share1b share ref_type/;

use Data::ParseBinary;
use ChronoBit::Bitcoin;

sub list {
	return Struct($_[0],
		var_int('length'),
		Array(sub { $_->ctx->{length} }, $_[1])
	)
}

sub small_block_header {
	return Struct($_[0],
		var_int('version'), # must be constrained to 32 bits, apparently
		Bytes('previous_block', 32),
		ULInt32('timestamp'),
		ULInt32('bits'),
		ULInt32('nonce')
	)
}

sub share_data {
	return Struct($_[0],
		Bytes('previous_share_hash', 32),
		var_bytes('coinbase'),
		ULInt32('nonce'),
		Bytes('pubkey_hash', 20),
		ULInt64('subsidy'),
		ULInt16('donation'),
		ULInt8('stale_info'), # 0 nothing, 253 orphan, 254 doa, apparently
		var_int('desired_version')
	)
}

sub share_info {
	return Struct($_[0],
		share_data('share_data'),
		Bytes('far_share_hash', 32),
		ULInt32('max_bits'),
		ULInt32('bits'),
		ULInt32('timestamp'),
	)
}

sub hash_link {
	return Struct($_[0],
		Bytes('state', 32),
		# extra_data is a 0-length string? :-O
		var_int('length')
	)
}

sub share_common {
	return Struct($_[0],
		small_block_header('min_header'),
		share_info('share_info'),
		Struct('ref_merkle_link',
			list('branch', Bytes('', 32)),
			var_int('index')
		),
		hash_link('hash_link')
	)
}

sub share1a {
	return Struct($_[0],
		share_common('common'),

		list('merkle_link', Bytes('branch', 32)),
		# here's apparently a 0-bit int which will always be 0 :-O
		# ah, that's gotta be gentx's index
	)
}

sub share1b {
	return Struct($_[0],
		share_common('common'),
		list('other_txs', tx)
	)
}

sub share {
	return Struct($_[0], 
		var_int('type'),
		var_int('contents_length'), # that's actually wrapping the remainder in var_str, but I want to avoid it
		Switch('contents', sub { $_->ctx->{type} }, {
			4 => share1a('1a'),
			5 => share1b('1b'),
		})
	)
}

sub ref_type {
	return Struct($_[0],
		Magic("\xfc\x70\x03\x5c\x7a\x81\xbc\x6f"), # XXX: that varies with network, but nvmd for now
		share_info('share_info'),
	)
}

# this is the donation script
our $gentx_before_refhash = 
	"\x43\x41\x04\xff\xd0\x3d\xe4\x4a\x6e\x11\xb9\x91\x7f\x3a\x29\xf9".
	"\x44\x32\x83\xd9\x87\x1c\x9d\x74\x3e\xf3\x0d\x5e\xdd\xcd\x37\x09".
	"\x4b\x64\xd1\xb3\xd8\x09\x04\x96\xb5\x32\x56\x78\x6b\xf5\xc8\x29".
	"\x32\xec\x23\xc3\xb7\x4d\x9f\x05\xa6\xf9\x5a\x8b\x55\x29\x35\x26".
	"\x56\x66\x4b\xac\x00\x00\x00\x00\x00\x00\x00\x00\x21\x20";

1;
