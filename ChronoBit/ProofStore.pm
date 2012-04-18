package ChronoBit::ProofStore;
use Any::Moose;

use IO::All;

use ChronoBit::Util;
use ChronoBit::ProofFile;

has 'outdir' => (is => 'rw');
has 'proofs' => (is => 'rw', isa => 'ArrayRef');
has 'froms' => (is => 'rw', isa => 'HashRef'); # maps from -> { to => idx, ... }
has 'tos' => (is => 'rw', isa => 'HashRef'); # maps to -> { from => idx, ... }

# adds a proof to the store and returns number of proofs added (0 if it already existed)
sub add {
	my ($self, $proof) = @_;

	unless(exists($self->froms->{$proof->from}->{$proof->to})) {
		my $idx = push(@{$self->proofs}, $proof) - 1;
		$self->froms->{$proof->from}->{$proof->to} = $idx;
		$self->tos->{$proof->to}->{$proof->from} = $idx;
		return 1;
	} else {
		return 0;
	}
}

# saves a proof to disk, returns a filename
sub save {
	my ($self, $proof, $proof_data) = @_;

	my $time = time;

	my $data = ChronoBit::ProofFile->struct->build({
		data => $proof_data || '',
		timestamp => $time,
		timestamp_usec => 0,
		proof => $proof,
	});

	my $outfile = io->catfile($self->outdir, sprintf("%s-%s-%d-%d-%d.proof",
		bin2hex($proof->from), bin2hex($proof->to), $time, 0, length($data)
	));

	$data > $outfile;
	$outfile->close;

	return $outfile->name;
}

1;
