package ChronoBit::JSONRPC;
use Any::Moose;

use JSON::XS;
use Log::Log4perl;
use Digest::SHA qw(sha256);

use ChronoBit::Util;
use ChronoBit::Bitcoin;
use ChronoBit::Proof;
use ChronoBit::ProofStore;

my $log = Log::Log4perl->get_logger(__PACKAGE__);

has 'cfg' => (is => 'ro');
has 'curhash' => (is => 'ro');
has 'hash_proofs' => (is => 'ro'); # maps a hash (hex) to an array of shares which have a proof for it
has 'our_shares' => (is => 'ro');  # maps a share's hash (hex) to a proof
has 'proof_store' => (is => 'rw');

sub BUILD {
	my ($self) = @_;

	$self->proof_store(ChronoBit::ProofStore->new(
		outdir => $self->cfg->{proofs},
	));
}

sub getauxblock {
	my ($self, @params) = @_;

	if(@params == 0) {
		# this is a call for our hash
		$log->trace('getauxblock called');
		return {
			chainid => int $self->cfg->{chainid},
			hash => defined($self->curhash) ? 
				bin2hex(scalar reverse hex2bin($self->curhash)) : 
				'00'x32,
			target => 'p2pool',
		};
	} else {
		# this is a response with a found p2pool share
		my ($hash, $pow_hex) = @params;
		$hash = bin2hex(scalar reverse hex2bin($hash));

		if($hash ne '00'x32) {
			my $pow = aux_pow->parse(hex2bin($pow_hex));
			my $share_hash = bin2hex($pow->{merkle_link}->{block_hash});
			
			$log->info("got p2pool share $share_hash for hash $hash");
			my $proof = ChronoBit::Proof->new_from_pow(hex2bin($hash), $pow);
			$self->proof_store->save($proof);
		} else {
			$log->debug("got p2pool response of empty hash, boring");
		}

		return JSON::XS::true;
	}
}

sub set_hash {
	my ($self, @params) = @_;

	$self->{curhash} = $params[0];
	return JSON::XS::true;
}

sub unset_hash {
	my ($self, @params) = @_;

	$self->{curhash} = undef;
	return JSON::XS::true;
}

sub debug {
	my ($self, @params) = @_;

	return { cur => $self->curhash };
}

sub all_methods {
	return qw/getauxblock set_hash unset_hash debug/;
}

1;
