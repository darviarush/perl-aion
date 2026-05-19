package Aion::Type;
# Базовый класс для типов и преобразователей
use common::sense;
use warnings FATAL => 'recursion';
#use warnings 'recursion';

use Aion::Meta::Util qw//;
use aliased 'Aion::Type::Lim';
use List::Util qw//;
use Scalar::Util qw//;

sub true {1}

use overload
	"fallback" => 1,
	"&{}" => sub {
		my ($self) = @_;
		sub { $self->test }
	},
	'""' => "stringify",
	"|" => sub { Aion::Types::Union([@_[0, 1]]) },
	"&" => sub { Aion::Types::Intersection([@_[0, 1]]) },
	"~" => sub { Aion::Types::Exclude([shift]) },
	"~~" => "include",
	">>" => "coerce",
	"eq" => "identical",
	"ne" => "distinct",
	"lt" => sub {die "lt do'nt used!"},
	"gt" => sub {die "gt do'nt used!"},
	"le" => sub {die "le do'nt used!"},
	"ge" => sub {die "ge do'nt used!"},
	"cmp" => sub {die "ge do'nt used!"},
	"==" => "identical",
	"!=" => "distinct",
	">=" => "superset",
	"<=" => "subset",
	">" => "superproper",
	"<" => "subproper",
	"<=>" => sub { my $le; ($le = $a->subset($b)) && $b->subset($a)? 0: $le? -1: 1 },
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

# Клонировать тип
sub clone {
	my $self = shift;
	$self = bless { %$self, @_ }, ref $self;
	delete @$self{qw/key as_test_cache/};
	$self
}

# Инициализировать тип
sub init {
	my ($self) = @_;

	# Есть параметрические типы – не инициализируем
	return $self if $self->{args} && List::Util::first { UNIVERSAL::isa($_, __PACKAGE__) && exists $_->{is_param} } @{$self->{args}};

	local $Aion::Type::SELF = $self;
	$_->() for @{$self->{init}};

	$self
}

#@category strings

# Строковое представление
sub stringify {
	my ($self) = @_;

	my @args = map Aion::Meta::Util::val_to_str($_), @{$self->{args}};

	$self->is_union? join "", "( ", join(" | ", @args), " )":
	$self->is_intersection? join "", "( ", join(" & ", @args), " )":
	$self->is_exclude? "~$args[0]":
	join("", $self->{name}, @args? ("[", join(", ", @args), "]") : ());
}

# Сообщение об ошибке
sub detail {
	(my $self, local $_, my $name) = @_;
	local $Aion::Type::SELF = $self;
	$self->{message}? do { local $self->{property} = $name; $self->{message}->() }:
		"$name must have the type $self. The it is ${\
			Aion::Meta::Util::val_to_str($_)
		}!"
}

# Преобразовать значение в строку
sub val_to_str {
	my ($self, $val) = @_;
	Aion::Meta::Util::val_to_str($val)
}

#@category test

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

# Валидировать значение в параметре
sub validate {
	(my $self, local $_, my $name) = @_;
	die $self->detail($_, $name) unless $self->test;
	$_
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

# refaddr coerce => минимальная нижняя граница. У Range она -Inf, а у остальных – 0
our %range_lbound;

# Определяет, что тип – множественно-теоретический оператор
my $set_theoretic = [qw/Union Intersection Exclude/];
sub is_set_theoretic { shift->{name} ~~ $set_theoretic }
sub is_union { shift->{name} eq 'Union' }
sub is_intersection { shift->{name} eq 'Intersection' }
sub is_exclude { shift->{name} eq 'Exclude' }
sub is_enum { shift->{name} eq 'Enum' }
sub is_range_type { exists $range_lbound{Scalar::Util::refaddr shift->{coerce}} }
sub range_lbound { $range_lbound{Scalar::Util::refaddr shift->{coerce}} }
sub is_range { shift->range_lbound == '-Inf' }

# Формирует ключ с отсортированными типизированными параметрами
sub typed_sorted_args_key {
	my ($self) = @_;
	my $coerceaddr = Scalar::Util::refaddr $self->{coerce};
	join "-", $coerceaddr, join(",", map { join ":", length($_), $_ } sort map $_->key, @{$self->{args}});
}

# Формирует ключ с отсортированными нетипизированными параметрами
sub sorted_args_key {
	my ($self) = @_;
	my $coerceaddr = Scalar::Util::refaddr $self->{coerce};
	join "-", $coerceaddr, join(",", map { join ":", length($_), $_ } sort @{$self->{args}});
}

# Возвращает уникальный ключ для типа, использующийся в хешах и сравнения
# Должен быть заменён на созданные типы
my %keyfn;
my $undefined = [];
sub key {
	my ($self) = @_;
	$self->{key} //= do {
		my $coerceaddr = Scalar::Util::refaddr $self->{coerce};
		my $keyfn = $keyfn{$coerceaddr};
		$keyfn
			? $keyfn->($self)
			: join "-", $coerceaddr, exists $self->{args} && @{$self->{args}} || exists $self->{N} || exists $self->{M}
				? join(",", map {
					my $key = UNIVERSAL::isa($_, __PACKAGE__)? $_->key: "" . ($_ // $undefined);
					join ":", length($key), $key 
				} @{$self->{args}})
				: ();
	};
}

# Устанавливает/возвращает функцию построения ключа для типа как класса
sub keyfn {
	my ($self, $fn) = @_;
	if(@_>1) {
		$keyfn{Scalar::Util::refaddr $self->{coerce}} = $fn;
		$self
	} else {
		$keyfn{Scalar::Util::refaddr $self->{coerce}}
	}
}

# (Int & Tel)->instanceof('Int') -> 1; (Int | Tel)->instanceof('Int') -> ""; (~(~Int | Tel))->instanceof('Int') -> ""
# Нечёткий поиск в иерархии по имени
sub instanceof {
	my ($self, $name) = @_;
	
	my @S = $self;
	while(@S) {
		my $x = pop @S;
		return 1 if $x->{name} eq $name;
		if($x->is_intersection) { push @S, @{$x->{args}} }
		elsif($x->is_set_theoretic) {}
		else { push @S, $x->{as} if $x->{as} }
	}
	
	""
}

# Тождество
sub identical {
	my ($self, $other) = @_;

	return 1 if Scalar::Util::refaddr $self == Scalar::Util::refaddr $other;
	return "" unless UNIVERSAL::isa($other, __PACKAGE__)
	 	&& $self->{coerce} == $other->{coerce};

	$self->key eq $other->key
}

# Нетождественно
sub distinct {
	my ($self, $other) = @_;
	!$self->identical($other);
}

my $_any; my $_none;
sub Any() { $_any //= &Aion::Types::Any }
sub None() { $_none //= ~Any }
sub hash(@) { map { ($_->key => $_) } @_ }

# Упрощение выражений
sub simplify { shift->_unfolding->_pushing->_distribute }

# A as B as C <=> A & B & C
sub _unfolding {
	my ($self) = @_;
	
	my @u;
	for(my $i=$self; $i; $i = $i->{as}) {
		push(@u, $i->clone(args => [map $_->_unfolding, @{$i->{args}}])), last if $i->is_set_theoretic;
		push @u, $i;
	}

	Aion::Types::Intersection(\@u);
}

# Проталкивание исключений к термам, заодно уменьшает размерность с приведением
sub _pushing {
	my ($self) = @_;
	
	if($self->is_exclude) {
		my $inner = $self->{args}[0];
		# ~(~A) => A
		return $inner->{args}[0]->_pushing if $inner->is_exclude;
		# ~(A | B) => ~A & ~B
		return _intersection(map { (~$_)->_pushing } @{$inner->{args}}) if $inner->is_union;
		# ~(A & B) => ~A | ~B
		return _union(map { (~$_)->_pushing } @{$inner->{args}}) if $inner->is_intersection;
		# Range[A, B] => Range[-Inf, Invert[A]] | Range[Invert[B], Inf]
		if($inner->is_range_type) {
			my ($min, $max) = @{$inner->{args}};
			if($inner->is_range) {
				return None if $min == '-Inf' && $max == 'Inf';
				return $inner->clone(args => [Aion::Type::Lim->from($max)->inc, 'Inf']) if $min == '-Inf';
				return $inner->clone(args => ['-Inf', Aion::Type::Lim->from($min)->dec]) if $max == 'Inf';
		        return $inner->clone(args => ['-Inf', Aion::Type::Lim->from($min)->dec]) | $inner->clone(args => [Aion::Type::Lim->from($max)->inc, 'Inf']);
			}
			
			return None if $min == 0 && $max == 'Inf';	
			return $inner->clone(args => [$max+1, 'Inf']) if $min == 0;		
			return $inner->clone(args => [0, $min-1]) if $max == 'Inf';		
			return $inner->clone(args => [0, $min-1]) | $inner->clone(args => [$max+1, 'Inf']);
		}
		return $self;
	}

	return _intersection(map $_->_pushing, @{$self->{args}}) if $self->is_intersection;
	return _union(map $_->_pushing, @{$self->{args}}) if $self->is_union;

	$self
}

# Сжимает в ДНФ
sub _distribute {
	my ($self) = @_;

	# (A|B) & (C|D|E) & F => (A&C&F) | (A&D&F) | (A&E&F) | (B&C&F) | (B&D&F) | (B&E&F)
	if($self->is_intersection) {
		my @disjuncts = map { my $x = $_->_distribute; $x->is_union? [@{$x->{args}}]: [$x] } @{$self->{args}};
		
		my $dnf = List::Util::reduce {
			[ map { my $p = $_; map { [@$p, $_] } @$b } @$a ]
		} [[]], @disjuncts;
		
		return _union(map _intersection(@$_), @$dnf);
	}

	return _union(map $_->_distribute, @{$self->{args}}) if $self->is_union;
	
	$self
}

# Объединение интервалов
sub _union_ranges {
	my ($ranges) = @_;

	# Отсекаем пустые
	my @ranges = grep $_->{args}[0] <= $_->{args}[1], @$ranges;

	# Сортируем в порядке возрастания нижней границы
	(my $range, @ranges) = sort { $a->{args}[0] <=> $b->{args}[0] } @ranges;

	@ranges = map {
		my ($min1, $max1) = @{$range->{args}};
		my ($min2, $max2) = @{$_->{args}};
		if($max1 > $min2) {	$range = Aion::Types::Range([$min1, List::Util::max($max1, $max2)]); () }
		else { my $arange = $range; $range = $_; $arange }
	} @ranges;
	push @ranges, $range;

	if(@ranges == 1) {
		my ($min, $max) = @{$range->{args}};
		return Any if $min == $range->range_lbound && $max == 'Inf';
	}

	@ranges
}

# Обрабатывает пересечение границ однотипных диапазонов
sub _intersection_ranges($) {
	my ($ranges) = @_;

	# Пустой диапазон - это None
	return None if 0 == grep $_->{args}[0] <= $_->{args}[1], @$ranges;
	
	# Сортируем в порядке возрастания нижней границы
	my ($range, @ranges) = sort { $a->{args}[0] <=> $b->{args}[0] } @$ranges;

	for my $arange (@ranges) {
		# Если хотя бы у одного нет пересечений – это None
		my ($min1, $max1) = @{$range->{args}};
		my ($min2, $max2) = @{$arange->{args}};
		my $max = List::Util::min($max1, $max2);
		return None if $min2 > $max;
		$range = Aion::Types::Range([$min2, $max]);
	}

	$range
}

# Объединение перечислений
sub _union_enums($,$) {
	my ($enums, $exclude_enums) = @_;
	
	my %enum = map {($_=>$_)} map @{$_->{args}}, @$enums;
	return $enums->[0]->clone(args => [values %enum]) unless @$exclude_enums;

	my $first_exclude_enum = shift(@$exclude_enums);
	my %exclude_enum = map {($_=>$_)} @{$first_exclude_enum->{args}};
	for my $exclude_enum (@$exclude_enums) {
		delete @exclude_enum{grep { !($_ ~~ $exclude_enum->{args}) } keys %exclude_enum};
		return Any unless keys %exclude_enum;
	}
	
	delete @exclude_enum{keys %enum};

	return Any unless keys %exclude_enum;

	~$first_exclude_enum->clone(args => [values %exclude_enum]);
}

# Пересечение перечислений
sub _intersection_enums($,$) {
	my ($enums, $exclude_enums) = @_;
	
	my %exclude_enum = map {($_=>$_)} map @{$_->{args}}, @$exclude_enums;
	return ~$exclude_enums->[0]->clone(args => [values %exclude_enum]) unless @$enums;
	
	my $first_enum = shift(@$enums);
	my %enum = map {($_=>$_)} @{$first_enum->{args}};

	for my $enum (@$enums) {
		delete @enum{grep { !($_ ~~ $enum->{args}) } keys %enum};
		return None unless keys %enum;
	}

	delete @enum{keys %exclude_enum};

	return None unless keys %enum;

	$first_enum->clone(args => [values %enum]);
}

# Обрабатывает пересечение границ диапазонов
sub _ranges_bag(@) {
	my $ranges_fn = shift;
	my $enums_fn = shift;
	my %bag; my @any; my @enums; my @exclude_enums;
	for my $candidate (@_) {
		my $addr = Scalar::Util::refaddr $candidate->{coerce};
		if(exists $range_lbound{$addr}) { push @{$bag{$addr}}, $candidate }
		elsif($candidate->is_enum) { push @enums, $candidate }
		elsif($candidate->is_exclude && $candidate->{args}[0]->is_enum) { push @exclude_enums, $candidate->{args}[0] }
		else { push @any, $candidate }
	}
	
	return @any, @enums || @exclude_enums? $enums_fn->(\@enums, \@exclude_enums): (), map $ranges_fn->($_), values %bag;
}

# Создание пересечения с приведением
sub _intersection(@) {
	my %x = hash _ranges_bag \&_intersection_ranges, \&_intersection_enums, map { $_->is_intersection? @{$_->{args}}: $_ } @_;
	# ~Any & A = ~Any
	return None if exists $x{None->key};
	# Any & A = A
	delete $x{Any->key};
	# Intersection[A] = A
	return (values %x)[0] if 1 == keys %x;
	# Intersection[] = Any
	return Any if 0 == keys %x;
	# A & ~A = ~Any
	return None if List::Util::first { $_->is_exclude && exists $x{$_->{args}[0]->key} } values %x;
	Aion::Types::Intersection([values %x]);
}

# Создание объединения с приведением
sub _union(@) {
	my %x = hash _ranges_bag \&_union_ranges, \&_union_enums, map { $_->is_union? @{$_->{args}}: $_ } @_;
	# Any | A = Any
	return Any if exists $x{Any->key};
	# ~Any | A = A
	delete $x{None->key};
	# Union[A] = A
	return (values %x)[0] if 1 == keys %x;
	# Union[] = None
	return None if 0 == keys %x;
	# A | ~A = Any
	return Any if List::Util::first { $_->is_exclude && exists $x{$_->{args}[0]->key} } values %x; 
	Aion::Types::Union([values %x]);
}

# A <= B  <=>  A & ~B = ∅
sub subset {
	my ($self, $other) = @_;

	return 1 if $self eq $other or $other eq Any;

 	($self & ~$other)->simplify eq None;
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

# Пересекаются
sub intersects {
	my ($self, $other) = @_;
	!$self->disjoint($other);
}

# Не пересекаются
sub disjoint {
	my ($self, $other) = @_;
	($self & $other)->simplify eq None;
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
	
	die "init_where won't work in $self->{name}" if $self->{init};
	
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
	my ($self, $pkg, $is_arg) = @_;

	my $hash = "%$self->{name}";
	my $proto = $is_arg? '$': '';

	if($is_arg) {
		my $init = $self->{init}? '->init': '';
		my $code = "package $pkg {
		my $hash = %\$self;
		sub $self->{name} (\$) { Aion::Type->new($hash, args => \$_[0])$init }
	}";
		eval $code;
		die if $@;
		return $self;
	}
	
	my $code = "package $pkg {
	my $hash = %\$self;
	sub $self->{name} () { Aion::Type->new($hash)->init }
}";
	eval $code;
	die if $@;

	$self
}

# Создаёт функцию для типа c аргументом или без.
# init вызывается только для типа с аргументами. Без аргументов возвращается один и тот же тип
sub make_maybe_arg {
	my ($self, $pkg) = @_;

	my $var = "\$$self->{name}";
	my $hash = "%$self->{name}";
	my $init = $self->{init}? '->init': '';

	my $code = "package $pkg;

	my $var = \$self;
	my $hash = %\$self;

	sub $self->{name} (;\$) {
		\@_==0? $var:
		Aion::Type->new(
			$hash,
			args => \$_[0],
			test => ${var}->{a_test},
		)$init
	}
";
	eval $code or die;
	
	$self
}


1;
