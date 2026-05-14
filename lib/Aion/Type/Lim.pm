package Aion::Type::Lim;
# Граница Range

use common::sense;

use overload
	"fallback" => 1,
	"<=>" => "compare",
	'""' => sub { my ($self) = @_; $self->{excluded}? "Opened[$self->{lim}]": "Closed[$self->{lim}]" },
;

# Конструктор
sub from {
	my ($cls, $lim) = @_;
	return bless {%$lim}, $cls if ref $lim eq $cls;
	bless { lim => $lim }, $cls;
}

# Сравнивает две границы
sub compare {
	my ($self, $other, $right) = @_;

	unless(UNIVERSAL::isa($other, __PACKAGE__)) {
		$other = __PACKAGE__->from($other);
		($other, $self) = ($self, $other) if $right;
	}
	
	$self->{lim} == $other->{lim} && !$self->{excluded} && !$other->{excluded}? 0:
	$self->{lim} < $other->{lim}
	|| $self->{lim} == $other->{lim} && $self->{excluded} && !$other->{excluded}? -1:
	1
}

sub lim { my ($self, $val) = @_; @_>1? do { $self->{lim} = $val; $self }: $self->{lim} }
sub opened { my ($self, $val) = @_; @_>1? $self->closed(!$val): $self->{excluded} }
sub closed { my ($self, $val) = @_; @_>1? do { $self->{excluded} = $self->is_inf? 0: !$val; $self }: !$self->{excluded} }
sub invert { my ($self) = @_; $self->opened($self->closed) }
sub is_inf { my $lim = shift->{lim}; $lim == 'Inf' || $lim == '-Inf' }

1;
