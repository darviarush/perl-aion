package Aion::Type;
# Базовый класс для типов и преобразователей

use common::sense;

use Scalar::Util qw/looks_like_number/;
require DDP;

use overload
	"fallback" => 1,
	"&{}" => sub { my ($self) = @_; sub { $self->test } },	# Чтобы тип мог быть выполнен
	'""' => \&stringify,									# Отображать тип в трейсбеке в строковом представлении
	"|" => sub {
		my ($type1, $type2) = @_;
		__PACKAGE__->new(name => "Union", args => [$type1, $type2], test => sub { $type1->test || $type2->test });
	},
	"&" => sub {
		my ($type1, $type2) = @_;
		__PACKAGE__->new(name => "Intersection", args => [$type1, $type2], test => sub { $type1->test && $type2->test });
	},
	"~" => sub {
		my ($type1) = @_;
		__PACKAGE__->new(name => "Exclude", args => [$type1], test => sub { !$type1->test });
	},
	"~~" => sub {
		(my $type, local $_) = @_;
		$type->test
	};

# конструктор
# * args (ArrayRef) — Список аргументов.
# * name (Str) — Имя метода.
# * test (CodeRef) — чекер.
# * coerce (CodeRef) — конвертер.
sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls;
}

# Символьное представление значения
sub _val_to_str {
	my ($v) = @_;
	!defined($v)			? "undef":
	looks_like_number($v)	? $v:
	ref($v)					? DDP::np($v, max_depth => 2, array_max => 13, hash_max => 13, string_max => 255):
	do {
		$v =~ s/[\\']/\\$&/g;
		$v =~ s/^/'/;
		$v =~ s/\z/'/;
		$v
	}
}

# Строковое представление
sub stringify {
	my ($self) = @_;
	join "", $self->{name}, $self->{args}? ("[", join(", ", map {
		UNIVERSAL::isa($_, __PACKAGE__)? $_->stringify: _val_to_str($_) } @{$self->{args}}), "]") : ();
}

# Тестировать значение в $_
our $SELF;
sub test {
	my ($self) = @_;
	my $save = $SELF;
	$SELF = $self;
	my $ok = $self->{test}->();
	$SELF = $save;
	$ok
}

# Инициализировать тип
sub init {
	my ($self) = @_;
	my $save = $SELF;
	$SELF = $self;
	$self->{init}->();
	$SELF = $save;
	$self
}

# Является элементом множества описываемого типом
sub include {
	(my $self, local $_) = @_;
	$self->test
}

# Не является элементом множества описываемого типом
sub exclude {
	(my $self, local $_) = @_;
	!$self->test
}

# Сообщение об ошибке
sub detail {
	my ($self, $val, $name) = @_;
	$self->{detail}? $self->{detail}->($val, $name):
		"Feature $name must have the type $self. The same $name is " . _val_to_str($val)
}

# Валидировать значение в параметре
sub validate {
	(my $self, local $_, my $name) = @_;
	die $self->detail($_, $name) if !$self->test;
	$_
}

# Преобразовать значение в параметре и вернуть преобразованное
sub coerce {
	(my $self, local $_) = @_;
	$self->{from}->test? $self->{coerce}->(): $_
}

# Создаёт функцию для типа
sub make {
	my ($self, $pkg) = @_;

	die "init_where не сработает в $self" if $self->{init};

	my $pkg = $pkg // caller;
	my $var = "\$$self->{name}";
	
	my $code = "package $pkg { 
	my $var = \$self;
	sub $self->{name} () { $var } 
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом
sub make_arg {
	my ($self, $pkg) = @_;

	my $pkg = $pkg // caller;
	my $var = "\$$self->{name}";
	my $init = $self->{init}? "->init": "";

	my $code = "package $pkg {
	
	my $var = \$self;
	
	sub $self->{name} (\$) {
		Aion::Type->new(
			%$var,
			args => \$_[0],
		)$init
	}
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом или без
sub make_maybe_arg {
	my ($self, $pkg) = @_;

	my $pkg = $pkg // caller;
	my $var = "\$$self->{name}";
	my $init = $self->{init}? "->init": "";

	my $code = "package $pkg {
	
	my $var = \$self;
	
	sub $self->{name} (;\$) {
		\@_==0? $var:
		Aion::Type->new(
			%$var,
			args => \$_[0],
			test => ${var}->{a_test},
		)$init
	}
}";
	eval $code;
	die if $@;

	$self
}


1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type - class of validators.

=head1 SYNOPSIS

	use Aion::Type;
	
	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	12   ~~ $Int # => 1
	12.1 ~~ $Int # -> ""
	
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	$Char->include("a")     # => 1
	$Char->exclude("ab")    # => 1
	
	my $IntOrChar = $Int | $Char;
	77   ~~ $IntOrChar # => 1
	"a"  ~~ $IntOrChar # => 1
	"ab" ~~ $IntOrChar # -> ""
	
	my $Digit = $Int & $Char;
	7  ~~ $Digit # => 1
	77 ~~ $Digit # -> ""
	
	"a" ~~ ~$Int; # => 1
	5   ~~ ~$Int; # -> ""

=head2  

=head1 METHODS

=head2 new (%ARGUMENTS)

Constructor.

=head3 ARGUMENTS

=head4 name

Name of type.

=head4 args

List of type arguments.

=head4 test

Subroutine for check value.

=head2 stringify

Stringify of object (name with arguments):

	my $Int = Aion::Type->new(
	    name => "Int",
	    args => [3, 5],
	);
	
	$Int->stringify  #=> Int[3, 5]

=head2 test

Testing the C<$_> belongs to the class.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	local $_ = 5;
	$PositiveInt->test  # -> 1
	local $_ = -6;
	$PositiveInt->test  # -> ""

=head2 init

Initial the validator.

	use DDP;
	my $Range = Aion::Type->new(
	    name => "Range",
	    args => [3, 5],
	    init => sub {
	        p my $x=$Aion::Type::SELF->{args};
	        @{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
	        my %x=%$Aion::Type::SELF;
	        p %x;
	    },
	    test => sub { p $Aion::Type::SELF->{min}; $Aion::Type::SELF->{min} <= $_ <= $Aion::Type::SELF->{max} },
	);
	
	$Range->init;
	
	3 ~~ $Range  # -> 1
	4 ~~ $Range  # -> 1
	5 ~~ $Range  # -> 1
	
	2 ~~ $Range  # -> ""
	6 ~~ $Range  # -> ""

=head2 include ($element)

checks whether the argument belongs to the class.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	$PositiveInt->include(5) # -> 1
	$PositiveInt->include(-6) # -> ""

=head2 exclude ($element)

Checks that the argument does not belong to the class.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	$PositiveInt->exclude(5)  # -> ""
	$PositiveInt->exclude(-6) # -> 1

=head1 OPERATORS

=head2 &{}

It make the object is callable.

=head2 ""

Stringify object.

=head2 $a | $b

It make new type as union of C<$a> and C<$b>.

=head2 $a & $b

It make new type as intersection of C<$a> and C<$b>.

=head2 ~ $a

It make exclude type from C<$a>.
