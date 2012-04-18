package ChronoBit::Bitcoin;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw/tx_out_point tx_in tx_out tx mrkllink block_header 
	aux_pow mm_coinbase var_int var_str var_bytes/;

use Data::ParseBinary;
use ChronoBit::Bitcoin::VarIntAdapter;
use ChronoBit::Bitcoin::VarStrAdapter;

sub var_int {
	return ChronoBit::Bitcoin::VarIntAdapter::var_int(@_);
}

sub var_str {
	return ChronoBit::Bitcoin::VarStrAdapter::var_str(@_);
}

sub var_bytes {
	return ChronoBit::Bitcoin::VarStrAdapter::var_bytes(@_);
}

sub tx_out_point {
	return Struct($_[0],
		Bytes('hash', 32),
		ULInt32('index')
	)
}

sub tx_in {
	return Struct($_[0],
		tx_out_point('previous_output'),
		var_int('script_length'),
		Field('signature_script', sub { $_->ctx->{script_length} }),
		ULInt32('sequence')
	)
}

sub tx_out {
	return Struct($_[0],
		ULInt64('value'),
		var_int('pk_script_length'),
		Field('pk_script', sub { $_->ctx->{pk_script_length} })
	)
}

sub tx {
	return Struct($_[0],
		ULInt32('version'),
		var_int('tx_in_count'),
		Array(sub { $_->ctx->{tx_in_count} }, tx_in('tx_in')),
		var_int('tx_out_count'),
		Array(sub { $_->ctx->{tx_out_count} }, tx_out('tx_out')),
		ULInt32('lock_time')
	)
}

sub mrkllink {
	return Struct($_[0],
		Bytes('block_hash', 32),
		var_int('branch_count'),
		Array(sub { $_->ctx->{branch_count} }, Bytes('branch', 32)),
		ULInt32('index')
	)
}

sub block_header {
	return Struct($_[0],
		ULInt32('version'),
		Bytes('prev_block', 32),
		Bytes('merkle_root', 32),
		ULInt32('timestamp'),
		ULInt32('bits'),
		ULInt32('nonce')
	)
}

sub aux_pow {
	return Struct($_[0],
		tx('coinbase_txn'),
		mrkllink('merkle_link'),
		var_int('aux_branch_count'),
		Array(sub { $_->ctx->{aux_branch_count} }, Bytes('aux_branch', 32)),
		ULInt32('index'),
		block_header('parent_block'),
		
	)
}

sub mm_coinbase {
	return Struct($_[0],
		Magic("\xfa\xbemm"),
		Bytes('block_hash', 32),
		ULInt32('merkle_size'),
		ULInt32('merkle_nonce')
	)
}

1;
