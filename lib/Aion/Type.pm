package Aion::Type;
# Базовый класс для типов и преобразователей
use common::sense;
use warnings FATAL => 'recursion';
#use warnings 'recursion';

use Aion::Meta::Util qw//;
use List::Util qw//;
use Scalar::Util qw//;

sub true {1}

BEGIN {
	*Aion::Types::Union = sub {
		my ($type1, $type2) = @{$_[0]};
		__PACKAGE__->new(name => "Union", args => [$type1, $type2], test => sub { $type1->test || $type2->test });
	} unless Aion::Types->can('Union');

	*Aion::Types::Intersection = sub {
		my ($type1, $type2) = @{$_[0]};
		__PACKAGE__->new(name => "Intersection", args => [$type1, $type2], test => sub { $type1->test && $type2->test });
	} unless Aion::Types->can('Intersection');
	
	*Aion::Types::Exclude = sub {
		my ($type1) = @{$_[0]};
		__PACKAGE__->new(name => "Exclude", args => [$type1], test => sub { !$type1->test });
	} unless Aion::Types->can('Exclude');	
}

use overload
	"fallback" => 1,
	"&{}" => sub {
		my ($self) = @_;
		sub { $self->test }
	},
	'""' => "stringify",
	"|" => sub { Aion::Types::Union([shift, shift]) },
	"&" => sub { Aion::Types::Intersection([shift, shift]) },
	"~" => sub { Aion::Types::Exclude([shift]) },
	"~~" => "include",
	"eq" => "identical",
	"ne" => "distinct",
	"==" => "equals",
	"!=" => "differs",
	">=" => "superset",
	"<=" => "subset",
	">" => "superproper",
	"<" => "subproper",
	">>" => "coerce",
;

Aion::Meta::Util::create_getters(qw/name args as/);
Aion::Meta::Util::create_accessors(qw/message/);

$Aion::Type::SELF = __PACKAGE__->new(
		is_param_args => __PACKAGE__->new(name => "Argument_ARGS", is_param => -1024),
	is_param => -256,
	name => 'Argument_SELF',
	args => [
		__PACKAGE__->new(name => "Argument_A", is_param => 1),
		__PACKAGE__->new(name => "Argument_B", is_param => 2),
		__PACKAGE__->new(name => "Argument_C", is_param => 3),
		__PACKAGE__->new(name => "Argument_D", is_param => 4),
	],
	N => __PACKAGE__->new(name => "Argument_N", is_param => -1),
	M => __PACKAGE__->new(name => "Argument_M", is_param => -2),
);

# конструктор
# * name (Str) — Имя типа.
# * as (Object[Aion::Type]) — наследуемый тип.
# * args (ArrayRef) — Список аргументов.
# * init (ArrayRef[CodeRef]) — Инициализатор типа.
# * test (CodeRef) — Чекер.
# * a_test (CodeRef) — Используется для проверки типа с аргументами, если аргументы не указаны, то используется test.
# * coerce (ArrayRef) — Массив преобразователей в этот тип: [Type => sub {}]. Общий для экземплятов параметрического типа.
# * subset (CodeRef) - Проверка на подмножество типа A типу B.
# * message (CodeRef) — Сообщение об ошибке.
# * title (Str) — Заголовок.
# * description (Str) — Описание.
# * example (Any) — Пример.
sub new {
	my $cls = shift;
	my $self = bless {@_}, $cls;
	$self->{test} //= \&test;
	$self->{coerce} //= [];
	$self
}

# Строковое представление
sub stringify {
	my ($self) = @_;

	my @args = map {
		UNIVERSAL::isa($_, __PACKAGE__)?
			$_->stringify:
			Aion::Meta::Util::val_to_str($_)
	} @{$self->{args}};

	$self->{name} eq "Union"? join "", "( ", join(" | ", @args), " )":
	$self->{name} eq "Intersection"? join "", "( ", join(" & ", @args), " )":
	$self->{name} eq "Exclude"? (
		@args == 1? join "", "~", @args:
			join "", "~( ", join(" | ", @args), " )"
	):
	join("", $self->{name}, @args? ("[", join(", ", @args), "]") : ());
}

# Строит кеш для вызова только для примитивного типа
sub _build_as_test_cache {
	my ($self) = @_;
	my @as;
	for(my $i = $self->{as}; $i; $i = $i->{as}) {
		return "" if $i->is_set_theoretic;
		unshift @as, $i if $i->{test} != \&true;
	}
	
	\@as;
}

# Это - примитивный тип, то есть тот, в иерархии которого нет множественно-теоритических операторов
sub is_primitive {
	my ($self) = @_;
	!!($self->{as_test_cache} //= $self->_build_as_test_cache);
}

# Тестировать значение в $_
sub test {
	my ($self) = @_;
	
	if($self->{as_test_cache} //= $self->_build_as_test_cache) {
		local $Aion::Type::SELF;
		for $Aion::Type::SELF (@{$self->{as_test_cache}}) {
			return "" unless $Aion::Type::SELF->{test}->();
		}
	} else {
		return "" if $self->{as} && !$self->{as}->test;
	}
	
	local $Aion::Type::SELF = $self;
	$self->{test}->();
}

# Инициализировать тип
sub init {
	my ($self) = @_;
	
	local $Aion::Type::SELF = $self;
	$_->() for @{$self->{init}};

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
	(my $self, local $_, my $name) = @_;
	local $Aion::Type::SELF = $self;
	local $Aion::Type::SELF->{N} = $name;
	$self->{message}? $self->{message}->():
		"$name must have the type $self. The it is ${\
			Aion::Meta::Util::val_to_str($_)
		}!"
}

# Валидировать значение в параметре
sub validate {
	(my $self, local $_, my $name) = @_;
	die $self->detail($_, $name) if !$self->test;
	$_
}

# Преобразовать значение в строку
sub val_to_str {
	my ($self, $val) = @_;
	Aion::Meta::Util::val_to_str($val)
}

# Преобразовать значение в параметре и вернуть преобразованное
sub coerce {
	local ($Aion::Type::SELF, $_) = @_;

	for my $coerce (@{$Aion::Type::SELF->{coerce}}) {
		return $coerce->[1]() if $coerce->[0]->test;
	}
	$_
}

#@category compare

# Определяет, что тип – множественно-теоретический оператор
my $set_theoretic = [qw/Union Intersection Exclude/];
sub is_set_theoretic {
	my ($self) = @_;
	$self->{name} ~~ $set_theoretic
}

## Определяет, что тип является подтипом другого типа
#sub instanceof {
#	my ($self, $other) = @_;
#	return "" unless UNIVERSAL::isa($other, __PACKAGE__);

#	my @S = [$self];
#	while(@S) {
#		my ($candidate, $excluded) = @{pop @S};

#		unless($excluded) {
#			return 1 if $candidate->identical($other);
			
#			if($candidate->{subset} && $candidate->{coerce} == $other->{coerce}) {
#				local ($Aion::Type::SELF, $_) = ($candidate, $other);
#				return 1 if $candidate->{subset}();
#				next;
#			}
#		}
		
#		if($candidate->is_set_theoretic) {
#			push @S, map [$_], @{$candidate->{args}} if !$excluded && $candidate->{name} eq "Intersection";
#			push @S, map [$_, !$excluded], @{$candidate->{args}} if $candidate->{name} eq "Exclude";
#			push @S, map [$_, 1], @{$candidate->{args}} if $excluded && $candidate->{name} eq "Union";
#		} else {
#			push @S, [$candidate->{as}, $excluded] if $candidate->{as};
#		}
#	}

#	""
#}

# (Int & Tel)->instanceof(Int) -> 1; (Int | Tel)->instanceof(Int) -> ""; (~(~Int | Tel))->instanceof(Int) -> 1
*instanceof = \&subset;

# Тождество
my $undefined = [];
sub identical {
	my ($self, $other) = @_;

	return 1 if Scalar::Util::refaddr $self == Scalar::Util::refaddr $other;
	return "" unless UNIVERSAL::isa($other, __PACKAGE__)	
	 	&& $self->{coerce} == $other->{coerce}
		&& @{$self->{args}} == @{$other->{args}};

	my $i = 0;
	for my $arg (@{$self->{args}}) {
		my $other_arg = $other->{args}[$i++];
		return "" unless ($arg // $undefined) eq ($other_arg // $undefined);
	}
	
	($self->{N} // $undefined) eq ($other->{N} // $undefined) and ($self->{M} // $undefined) eq ($other->{M} // $undefined);
}

# Нетождественно
sub distinct {
	my ($self, $other) = @_;
	!$self->identical($other);
}

# Вспомогательная функция для удаления дубликатов
sub _uniqt($) {
	my ($simplify) = @_;
	for my $intersection (@$simplify) {
		my @res;
		for my $item (@$intersection) {
			push @res, $item unless List::Util::first { ref $item eq ref $_ && (ref $item eq "REF"? $$item->identical($$_): $item->identical($_)) } @res;
		}
		@$intersection = @res;
    }
    $simplify
}

# Упрощает выражение и переводит его в двухуровневую форму
# A & B | ~(C & X) <=> [[A,B], [\C], [\X]]
sub _simplify2level {
    my ($self) = @_;

    # 1. A | B
    if ($self->{name} eq 'Union') {
        return _uniqt [ map { @{$_->_simplify2level} } @{$self->{args}} ];
    }

    # 2. A & B
    if ($self->{name} eq 'Intersection') {
    	my @args = map $_->_simplify2level, @{$self->{args}};
        # Перемножение всех комбинаций (дистрибутивность): (A|B) & (C|D) => AC|AD|BC|BD
        my $result = List::Util::reduce {
            [ map { my $comb = $_; map { [@$comb, @$_] } @$b } @$a ]
        } [[]], @args;
        return _uniqt $result;
    }

    # 3. ~((A & B) | (C & ~D)) <=> (~(A & B) & ~(C & ~D)) <=> (~A | ~B) & (~C | D) => \A\C|\AD|\B\C|\BD
    if ($self->{name} eq 'Exclude') {
        my $inner = $self->{args}[0]->_simplify2level;
        
        # Шаг 1: отрицаем каждый конъюнкт: [a,b] -> [~a, ~b]
        my @negated = map [map { ref $_ eq 'REF' ? $$_ : \$_ } @$_], @$inner;
        
        return [map [$_], @{$negated[0]}] if @negated == 1;
        
        # Шаг 2: перемножаем все комбинации (декартово произведение) между разными ~конъюнктами
        my $result = List::Util::reduce {
            [ map { my $comb = $_; map { [@$comb, @$_] } @$b } @$a ]
        } [[]], \@negated;
        
        return _uniqt $result;
    }

    # 4. A as B => A & B
    if ($self->{as}) {
        return [map [$self, @$_], @{$self->{as}->_simplify2level}];
    }
    
    if ($self ne &Aion::Types::Any) {
    	return [map [$self, @$_], @{Aion::Types::Any()->_simplify2level}];
    }

    # A => [[A]]
    return [[ $self ]];
}

# Распознаёт пустые множества
sub _not_empty {
	my ($intersection) = @_;
	my @negated = map $$_, grep ref $_ eq 'REF', @$intersection;
	return 1 unless scalar @negated;
	my @positived = grep ref $_ ne 'REF', @$intersection;
	my $any = &Aion::Types::Any; 
	for my $neg (@negated) {
		return "" if $neg eq $any;
		for my $pos (@positived) {
			return "" if $neg eq $pos;
		}
	}
	return 1;
}

# 
sub _simplify {
	my ($self) = @_;

	my $simplify = $self->_simplify2level;
	use DDP; p my $x=["hi!", $simplify];
	# A & ~A = ~Any, ~Any & A = ~Any, Any & ~Any = ~Any
	# Отбрасываем пустые множества:
	@$simplify = grep _not_empty($_), @$simplify;
	
	$simplify
}

# Упрощает выражение
sub simplify {
	my ($self) = @_;
	
	my $simplify = $self->_simplify;
	
	my $any = &Aion::Types::Any;
	return ~$any unless scalar @$simplify;
	
	# Any | A = Any
	return $any if List::Util::first { @$_ == 1 && $_->[0] eq $any } @$simplify;
	
	my @uni = map {
		my @int = map { ref $_ eq 'REF'? ~$$_: $_ } @$_;
		@int == 1? $int[0]: Aion::Types::Intersection(\@int);
	} @$simplify;
	
	@uni == 1? $uni[0]: Aion::Types::Union(\@uni);
}

sub _disjoint {
    my ($self, $other) = @_;

    # 1. Тождественные типы пересекаются (не дизъюнктны)
    return 0 if $self->identical($other);

    # 2. Если один из них Union (A | B), то он дизъюнктен с X, 
    # только если И A, И B дизъюнктны с X
    if ($self->{name} eq 'Union') {
        return $self->{args}[0]->_disjoint($other)
            && $self->{args}[1]->_disjoint($other);
    }
    if ($other->{name} eq 'Union') {
        return $other->{args}[0]->_disjoint($self)
            && $other->{args}[1]->_disjoint($self);
    }

    # 3. Базовая логика для примитивов
    # Если это разные встроенные типы, например Int и String
    if ($self->{is_primitive} && $other->{is_primitive}) {
        return 1 if $self->{name} ne $other->{name};
    }

    # 4. Если один наследует другой (через 'as'), они пересекаются
    return 0 if $self->{as} && $self->{as}->equals($other);
    return 0 if $other->{as} && $other->{as}->equals($self);

    # По умолчанию считаем, что могут пересекаться (безопасный вариант)
    return 0;
}

# A <= B = A eq B || A is_subtype B
sub subset {
	my ($self, $other) = @_;
	
	return 1 if $self->identical($other);

	# 1. Если справа Exclude (~X): A <= ~B <=> A и B не пересекаются = None
	if ($other->{name} eq 'Exclude') {
		return $self->_disjoint($other->{args}[0]);
	}

	# 2. Если слева Exclude (~X): ~A <= B <=> A | B поглощают вселенную = Any
	if ($self->{name} eq 'Exclude') {
	    return $other->{name} ~~ ['Any', 'Item'];
	}
	
	# 3. Если слева Union: (A | B) <= X <=> A <= X && B <= X
	if($self->{name} eq 'Union') {
		return $self->{args}[0]->subset($other) && $self->{args}[1]->subset($other);
	}

	# 4. Если слева Intersection: (A & B) <= X <=> A <= X || B <= X
	if($self->{name} eq 'Intersection') {
		return $self->{args}[0]->subset($other) || $self->{args}[1]->subset($other);
	}

	# 5. Если справа Union: A <= (B | C) <=> A <= B || A <= C
	if($other->{name} eq 'Union') {
		return $self->subset($other->{args}[0]) || $self->subset($other->{args}[1]);
	}

	# 6. Если справа Intersection: A <= (B & C) <=> A <= B && A <= C
	if($other->{name} eq 'Intersection') {
		return $self->subset($other->{args}[0]) && $self->subset($other->{args}[1]);
	}
		
	if($self->{subset} && $self->{coerce} == $other->{coerce}) {
		local ($Aion::Type::SELF, $_) = ($self, $other);
		return $self->{subset}();
	}
	
	$self->{as}? $self->{as}->subset($other): "";
}

# A < B (Строгое включение: подтип, но не равен) = A <= B && !(B <= A)
sub subproper {
	my ($self, $other) = @_;
	$self->subset($other) && !$other->subset($self);
}

# A >= B = B <= A
sub superset {
	my ($self, $other) = @_;
	$other->subset($self);
}

# A > B = B < A
sub superproper {
	my ($self, $other) = @_;
	$other->subproper($self);
}

# A == B (Эквивалентность типов: A является подтипом B И B является подтипом A) = A <= B && B <= A
sub equals {
	my ($self, $other) = @_;
	$self->subset($other) && $other->subset($self);
}

sub differs {
	my ($self, $other) = @_;
	!$self->equals($other);
}

#@category swagger

# Заголовок
sub title {
	my ($self, $title) = @_;
	if(@_ == 1) {
		$self->{title}
	} else {
		bless {%$self, title => $title}, ref $self
	}
}

# Описание
sub description {
	my ($self, $description) = @_;
	if(@_ == 1) {
		$self->{description}
	} else {
		bless {%$self, description => $description}, ref $self
	}
}

# Описание
sub example {
	my ($self, $description) = @_;
	if(@_ == 1) {
		$self->{example}
	} else {
		bless {%$self, example => $description}, ref $self
	}
}

#@category makers

# Создаёт функцию для типа
sub make {
	my ($self, $pkg) = @_;
	
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
	my ($self, $pkg, $proto) = @_;

	my $var = "\$$self->{name}";
	$proto //= '$';

	my $code = "package $pkg {

	my $var = \$self;

	sub $self->{name} ($proto) {
		Aion::Type->new(
			%$var,
			args => \$_[0],
		)->init
	}
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом или без
sub make_maybe_arg {
	my ($self, $pkg) = @_;

	my $var = "\$$self->{name}";

	my $code = "package $pkg;

	my $var = \$self;

	sub $self->{name} (;\$) {
		\@_==0? $var:
		Aion::Type->new(
			%$var,
			args => \$_[0],
			test => ${var}->{a_test},
		)->init
	}
";
	eval $code or die;
	
	$self
}


1;

__END__

=encoding utf-8

=head1 NAME

Aion::Type - class of validators

=head1 SYNOPSIS

	use Aion::Type;
	
	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	12   ~~ $Int # => 1
	12.1 ~~ $Int # -> ""
	
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	$Char->include("a")	 # => 1
	$Char->exclude("ab") # => 1
	
	my $IntOrChar = $Int | $Char;
	77   ~~ $IntOrChar # => 1
	"a"  ~~ $IntOrChar # => 1
	"ab" ~~ $IntOrChar # -> ""
	
	my $Digit = $Int & $Char;
	7  ~~ $Digit # => 1
	77 ~~ $Digit # -> ""
	
	"a" ~~ ~$Int; # => 1
	5   ~~ ~$Int; # -> ""
	
	eval { $Int->validate("a", "..Eval..") }; $@ # ~> ..Eval.. must have the type Int. The it is 'a'

=head1 DESCRIPTION

Spawns validators. Used in C<Aion::Types::subtype>.

=head1 METHODS

=head2 new (%ARGUMENTS)

Constructor.

=head3 ARGUMENTS

=over

=item * name (Str) — Type name.

=item * args (ArrayRef) — List of type arguments.

=item * init (CodeRef) — Type initializer.

=item * test (CodeRef) - Checker.

=item * a_test (CodeRef) — Value checker for types with optional arguments.

=item * coerce (ArrayRef[Tuple[Aion::Type, CodeRef]]) - Array of pairs: type and transition.

=back

=head2 stringify

String conversion of object (name with arguments):

	my $Char = Aion::Type->new(name => "Char");
	
	$Char->stringify # => Char
	
	my $Int = Aion::Type->new(
		name => "Int",
		args => [3, 5],
	);
	
	$Int->stringify  #=> Int[3, 5]

Operations are also converted to a string:

	($Int & $Char)->stringify   # => ( Int[3, 5] & Char )
	($Int | $Char)->stringify   # => ( Int[3, 5] | Char )
	(~$Int)->stringify		  # => ~Int[3, 5]

Operations are C<Aion::Type> objects with special names:

	Aion::Type->new(name => "Exclude", args => [$Int, $Char])->stringify   # => ~( Int[3, 5] | Char )
	Aion::Type->new(name => "Union", args => [$Int, $Char])->stringify   # => ( Int[3, 5] | Char )
	Aion::Type->new(name => "Intersection", args => [$Int, $Char])->stringify   # => ( Int[3, 5] & Char )

=head2 test

Tests that C<$_> belongs to a class.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	local $_ = 5;
	$PositiveInt->test  # -> 1
	local $_ = -6;
	$PositiveInt->test  # -> ""

=head2 init

Validator initializer.

	my $Range = Aion::Type->new(
		name => "Range",
		args => [3, 5],
		init => [sub {
			@{$Aion::Type::SELF}{qw/min max/} = @{$Aion::Type::SELF->{args}};
		}],
		test => sub { $Aion::Type::SELF->{min} <= $_ && $_ <= $Aion::Type::SELF->{max} },
	);
	
	$Range->init;
	
	3 ~~ $Range  # -> 1
	4 ~~ $Range  # -> 1
	5 ~~ $Range  # -> 1
	
	2 ~~ $Range  # -> ""
	6 ~~ $Range  # -> ""

=head2 include ($element)

Checks whether the argument belongs to the class.

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

=head2 coerce ($value)

Cast C<$value> to type if the cast from type and function is in C<< $self-E<gt>{coerce} >>.

Corresponds to the C<< E<gt>E<gt> >> operator.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+\z/ });
	my $Num = Aion::Type->new(name => "Num", test => sub { /^-?\d+(\.\d+)?\z/ });
	my $Bool = Aion::Type->new(name => "Bool", test => sub { /^(1|0|)\z/ });
	
	push @{$Int->{coerce}}, [$Bool, sub { 0+$_ }];
	push @{$Int->{coerce}}, [$Num, sub { int($_+.5) }];
	
	$Int->coerce(5.5)	# => 6
	$Int->coerce(undef)  # => 0
	$Int->coerce("abc")  # => abc

=head2 detail ($element, $feature)

Generates an error message.

	my $Int = Aion::Type->new(name => "Int");
	
	$Int->detail(-5, "Feature car") # => Feature car must have the type Int. The it is -5!
	
	my $Num = Aion::Type->new(name => "Num", message => sub {
		"Error: $_ is'nt $Aion::Type::SELF->{N}!"
	});
	
	$Num->detail("x", "car") # => Error: x is'nt car!

C<< $Aion::Type::SELF-E<gt>{N} >> equivalent to C<N> in context of C<Aion::Types>.

=head2 validate ($element, $feature)

Checks C<$element> and throws a C<detail> message if the element does not belong to the class.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	eval {
		$PositiveInt->validate(-1, "Neg")
	};
	$@ # ~> Neg must have the type PositiveInt. The it is -1

=head2 val_to_str ($val)

Converts C<$val> to a string.

	Aion::Type->new->val_to_str([1,2,{x=>6}]) # => [1, 2, {x => 6}]

=head2 instanceof ($type)

Specifies that a type is a subtype of another C<$type>.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	
	$PositiveInt->instanceof($Int)          # -> 1
	$PositiveInt->instanceof($PositiveInt)  # -> 1
	$Int->instanceof($PositiveInt)          # -> ""

=head2 is_set_theoretic

Checks that the type is set-theoretic (ie - the C<|>, C<&> or C<~> operator).

=head2 identical ($type)

Types are equal if they have the same prototype (C<coerce>), the same number of arguments, parent element, their arguments, and M and N are equal.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	my $AnotherInt = Aion::Type->new(name => "Int", coerce => $Int->{coerce});
	my $IntWithArgs = Aion::Type->new(name => "Int", args => [1, 2]);
	my $AnotherIntWithArgs = Aion::Type->new(name => "Int", args => [1, 2], coerce => $IntWithArgs->{coerce});
	my $IntWithDifferentArgs = Aion::Type->new(name => "Int", args => [3, 4]);
	my $Str = Aion::Type->new(name => "Str");
	
	$Int->identical($Int)                        # -> 1
	$Int->identical($AnotherInt)                 # -> 1
	$IntWithArgs->identical($AnotherIntWithArgs) # -> 1
	$PositiveInt->identical($PositiveInt)        # -> 1
	
	$Int->{coerce} == $Str->{coerce}               # -> ""
	$Int->identical($Str)                          # -> ""
	$Int->identical($IntWithArgs)                  # -> ""
	$IntWithArgs->identical($IntWithDifferentArgs) # -> ""
	$PositiveInt->identical($Int)                  # -> ""
	
	$Int->identical("not a type") # -> ""
	
	my $PositiveInt2 = Aion::Type->new(name => "PositiveInt", as => $Str);
	$PositiveInt->identical($PositiveInt2) # -> ""
	
	$Int->identical($PositiveInt) # -> ""
	$PositiveInt->identical($Int) # -> ""
	
	my $PositiveIntWithArgs = Aion::Type->new(name => "PositiveInt", as => $Int, args => [1]);
	my $PositiveIntWithArgs2 = Aion::Type->new(name => "PositiveInt", as => $Int, args => [2]);
	$PositiveIntWithArgs->identical($PositiveIntWithArgs2) # -> ""

=head2 distinct ($type)

Reverse operation to C<identical>.

	my $Int = Aion::Type->new(name => "Int");
	my $PositiveInt = Aion::Type->new(name => "PositiveInt", as => $Int);
	
	$Int->distinct($PositiveInt) # -> 1
	$Int ne $PositiveInt         # -> 1

=head2 disjoint ($other)

A type does not overlap with another type.

=head2 subset ($type)

Specifies that it is a subset of the specified type.

=head2 superset ($type)

Specifies that it is a superset of the specified type.

=head2 subproper ($other)

A type is a strict subset of another.

=head2 superproper ($other)

A type is a strict superset of another.

=head2 equals ($other)

Type is equal to another.

=head2 differs ($other)

The type is different from another (the reverse operation to C<equals>).

=head2 make ($pkg)

Creates a subroutine with no arguments that returns a type.

	BEGIN {
		Aion::Type->new(name=>"Rim", test => sub { /^[IVXLCDM]+$/i })->make(__PACKAGE__);
	}
	
	"IX" ~~ Rim	 # => 1

The C<init> property cannot be used with C<make>.

	eval { Aion::Type->new(name=>"Rim", init => sub {...})->make(__PACKAGE__) }; $@ # ~> init_where won't work in Rim

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make }; $@ # ~> syntax error

=head2 make_arg ($pkg)

Creates a subroutine with arguments that returns a type.

	BEGIN {
		Aion::Type->new(name=>"Len", test => sub {
			$Aion::Type::SELF->{args}[0] <= length($_) && length($_) <= $Aion::Type::SELF->{args}[1]
		})->make_arg(__PACKAGE__);
	}
	
	"IX" ~~ Len[2,2] # => 1

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make_arg }; $@ # ~> syntax error

=head2 make_maybe_arg ($pkg)

Creates a subroutine with arguments that returns a type.

	BEGIN {
		Aion::Type->new(
			name => "Enum123",
			test => sub { $_ ~~ [1,2,3] },
			a_test => sub { $_ ~~ $Aion::Type::SELF->{args} },
		)->make_maybe_arg(__PACKAGE__);
	}
	
	3 ~~ Enum123        # -> 1
	3 ~~ Enum123[4,5,6] # -> ""
	5 ~~ Enum123[4,5,6] # -> 1

If the routine cannot be created, an exception is thrown.

	eval { Aion::Type->new(name=>"Rim")->make_maybe_arg }; $@ # ~> syntax error

=head2 args ()

List of arguments.

=head2 name ()

Type name.

=head2 as ()

Parent type.

=head2 message (;&message)

Message accessor. Uses C<&message> to generate an error message.

=head2 title (;$title)

Header accessor (used to create the B<swagger> schema).

=head2 description (;$description)

Description accessor (used to create a B<swagger> schema).

=head2 example (;$example)

Example accessor (used to create the B<swagger> schema).

=head1 OPERATORS

=head2 &{}

Tests C<$_>.

	my $PositiveInt = Aion::Type->new(
		name => "PositiveInt",
		test => sub { /^\d+$/ },
	);
	
	local $_ = 10;
	$PositiveInt->()	# -> 1
	
	$_ = -1;
	$PositiveInt->()	# -> ""

=head2 ""

Strings an object.

	Aion::Type->new(name => "Int") . ""   # => Int
	
	my $Enum = Aion::Type->new(name => "Enum", args => [qw/A B C/]);
	
	"$Enum" # => Enum['A', 'B', 'C']

=head2 |

Or. Creates a new type as a union of two.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $IntOrChar = $Int | $Char;
	
	77   ~~ $IntOrChar # -> 1
	"a"  ~~ $IntOrChar # -> 1
	"ab" ~~ $IntOrChar # -> ""

=head2 &

I. Creates a new type as the intersection of two.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	my $Char = Aion::Type->new(name => "Char", test => sub { /^.\z/ });
	
	my $Digit = $Int & $Char;
	
	7  ~~ $Digit # -> 1
	77 ~~ $Digit # -> ""
	"a" ~~ $Digit # -> ""

=head2 ~

Not. Creates a new type as an exception to the given one.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	"a" ~~ ~$Int; # -> 1
	5   ~~ ~$Int; # -> ""

=head2 ~~

Tests the value.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	
	$Int ~~ 3    # -> 1
	-6   ~~ $Int # -> 1

=head2 >>

Casting to type.

	my $Int = Aion::Type->new(name => "Int", test => sub { /^-?\d+$/ });
	$Int->{coerce} = [[$Int => sub { $_ + 5 }]];
	
	5 >> $Int # -> 10
	
	$Int >> -4 # -> 1

=head2 eq

The types are identical.

=head2 ne

The types are different.

=head2 ==

Compares two types.

	my $Int1 = Aion::Type->new(name => "Int1");
	my $Int2 = Aion::Type->new(name => "Int2", coerce => $Int1->{coerce});
	
	$Int1 == $Int2 # -> 1
	$Int1 eq $Int2 # -> 1
	
	my $Enum1 = Aion::Type->new(
		name => "Enum",
		args => ['red', 'green'],
		subset => sub {
			my $other_args = $_->{args};
			List::Util::all { $_ ~~ $other_args } @{$Aion::Type::SELF->{args}}
		},
	);
	my $Enum2 = Aion::Type->new(
		name => "Enum",
		args => ['green', 'red'],
		coerce => $Enum1->{coerce},
		subset => $Enum1->{subset},
	);
	
	$Enum1 eq $Enum2 # -> ""
	$Enum1 == $Enum2 # -> 1

=head2 !=

Checks that the types are not equal.

	my $Int1 = Aion::Type->new(name => "Int");
	my $Int2 = Aion::Type->new(name => "Int");
	
	$Int1 != $Int2 # -> 1
	123   != $Int2 # -> 1

=head2 <

A is a strict subset of B.

	my $Num = Aion::Type->new(name => "Num");
	my $Int = Aion::Type->new(name => "Int", as => $Num);
	my $Str = Aion::Type->new(name => "Str");
	
	$Int < $Num # -> 1
	$Int < ($Int | $Str) # -> 1
	$Int < ($Num | $Str) # -> 1
	
	$Num < $Int # -> ""
	$Int < $Int # -> ""
	($Num | $Str) < $Int # -> ""

=head2 >

A is a strict superset of B.

=head2 <=

A is a subset of B.

=head2 >=

A is a superset of B.

=head1 AUTHOR

Yaroslav O. Kosmina L<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>

=head1 COPYRIGHT

The Aion::Type module is copyright © 2023 Yaroslav O. Kosmina. Rusland. All rights reserved.
