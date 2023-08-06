package Aion::Coerce;
# Базовый класс для преобразователей

use common::sense;

use Scalar::Util qw/looks_like_number/;
require DDP;

use overload
	"fallback" => 1,
	"&{}" => sub { my ($self) = @_; sub { $self->test } },	# Чтобы тип мог быть выполнен
	'""' => \&stringify,									# Отображать тип в трейсбеке в строковом представлении
	"&" => sub {
		my ($type1, $type2) = @_;
		__PACKAGE__->new(name => "Intersection", args => [$type1, $type2], test => sub { $type1->test && $type2->test });
	},
	"~~" => sub {
		(my $type, local $_) = @_;
		$type->coerce
	};

# конструктор
# * args (ArrayRef) — Список аргументов.
# * name (Str) — Имя метода.
# * coerce (CodeRef) — конвертер.
sub new {
	my $cls = shift;
	bless {@_}, ref $cls || $cls;
}

# Символьное представление значения
sub val_to_str {
	my ($self, $v) = @_;
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
		UNIVERSAL::isa($_, __PACKAGE__)? $_->stringify: $self->val_to_str($_) } @{$self->{args}}), "]") : ();
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
		"Feature $name must have the type $self. The same $name is " . $self->val_to_str($val)
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

	my $Range = Aion::Type->new(
	    name => "Range",
	    args => [3, 5],
	    init => sub {
	        @{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
	    },
	    test => sub { $Aion::Type::SELF->{min} <= $_ <= $Aion::Type::SELF->{max} },
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

=head2 detail ($element, $feature)

Return message belongs to error.

	my $Int = Aion::Type->new(name => "Int");
	
	$Int->detail(-5, "car") # => Feature car must have the type Int. The same car is -5
	
	my $Num = Aion::Type->new(name => "Num", detail => sub {
	    my ($val, $name) = @_;
	    "Error: $val is'nt $name!"
	});
	
	$Num->detail("x", "car")  # => Error: x is'nt car!

=head2 validate ($element, $feature)

It tested C<$element> and throw C<detail> if element is exclude from class.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	eval {
	    $PositiveInt->validate(-1, "Neg")
	};
	$@   # ~> Feature Neg must have the type PositiveInt. The same Neg is -1

=head2 val_to_str ($element)

Translate C<$val> to string.

	Aion::Type->val_to_str([1,2,{x=>6}])   # => [\n    [0] 1,\n    [1] 2,\n    [2] {\n            x   6\n        }\n]

=head1 OPERATORS

=head2 &{}

It make the object is callable.

	my $PositiveInt = Aion::Type->new(
	    name => "PositiveInt",
	    test => sub { /^\d+$/ },
	);
	
	local $_ = 10;
	$PositiveInt->()    # -> 1
	
	$_ = -1;
	$PositiveInt->()    # -> ""

=head2 ""

Stringify object.

	Aion::Type->new(name => "Int") . ""   # => Int
	
	my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);
	
	"$Enum" # => Enum['A', 'B', 'C']

=head2 $a | $b

It make new type as union of C<$a> and C<$b>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $IntOrChar = $Int | $Char;
	
	77   ~~ $IntOrChar # => 1
	"a"  ~~ $IntOrChar # => 1
	"ab" ~~ $IntOrChar # -> ""

=head2 $a & $b

It make new type as intersection of C<$a> and C<$b>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $Digit = $Int & $Char;
	
	7  ~~ $Digit # => 1
	77 ~~ $Digit # -> ""

=head2 ~ $a

It make exclude type from C<$a>.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	"a" ~~ ~$Int; # => 1
	5   ~~ ~$Int; # -> ""

