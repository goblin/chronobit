# base class that wraps up the Data::ParseBinary and provides methods
# for parse and build.

package ChronoBit::StructClass;
use Any::Moose 'Role';

requires 'struct';

sub dump {
	my ($self) = @_;

	return $self->struct->build($self);
}

sub new_from_binary {
	my ($class, $bytes) = @_;

	$class->new($class->struct->parse($bytes));
}

1;
