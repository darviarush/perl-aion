package Aion::Types;
# Типы-валидаторы для Aion

use common::sense;
use warnings FATAL => 'recursion';

use Aion::Meta::Util qw/subref_is_reachable val_to_str/;
use Aion::Type;
use Aion::Type::Lim;
use List::Util qw/all any first/;
use Exporter qw/import/;
require overload;
use POSIX qw//;
use Scalar::Util qw/looks_like_number reftype refaddr blessed/;
use Sub::Util qw//;

our @EXPORT = our @EXPORT_OK = grep {
	eval {*{$Aion::Types::{$_}}{CODE}}	&& !/^(_|(NaN|import|all|any|first|looks_like_number|reftype|refaddr|blessed|subref_is_reachable|val_to_str|DBL_MAX)\z)/n
} keys %Aion::Types::;

# Обрабатываем атрибут :Isa
sub MODIFY_CODE_ATTRIBUTES {
    my ($pkg, $referent, @attributes) = @_;

    grep { /^Isa\((.*)\)\z/s? do { _Isa($pkg, $referent, $1); 0 }: 1 } @attributes
}

sub _Isa {
	my ($pkg, $referent, $data) = @_;
	my $subname = Sub::Util::subname $referent;
	$subname =~ s/^.*:://;

	die "Anonymous subroutine cannot use :Isa!" if $subname eq '__ANON__';
	
	my @signature = eval "package $pkg; map { UNIVERSAL::isa(\$_, 'Aion::Type')? \$_: __PACKAGE__->can(\$_)? __PACKAGE__->can(\$_)->(): Aion::Types::External([\$_]) } ($data)";
	die if $@;

	die "$pkg\::$subname has no return type!" if @signature == 0;

	require Aion::Meta::Subroutine;
	my $subroutine = Aion::Meta::Subroutine->new(
		pkg => $pkg,
		subname => $subname,
		signature => \@signature,
		referent => $referent,
	);
	
	if(!subref_is_reachable($referent)) {
		$Aion::META{$pkg}{require}{$subname} = $subroutine;
	} else {
		my $require = delete $Aion::META{$pkg}{require}{$subname};
		$require->compare($subroutine) if $require;

		my $overload = $Aion::META{$pkg}{subroutine}{$subname};
		$overload->compare($subroutine) if $overload;
		
		$subroutine->wrap_sub;
	}	
}

BEGIN {
my $INIT_ARGS = sub { @{&ARGS} = map External([$_]), &ARGS };
my $INIT_KW_ARGS = sub { @{&ARGS} = List::Util::pairmap { $a => External([$b]) } &ARGS };

my $COMBINE_SUBS = sub {
    my ($f1, $f2) = @_;
    sub { $f1->(); $f2->() }
};

my $COMBINE_WHERE = sub {
    my ($f1, $f2) = @_;
    sub { $f1->() && $f2->() }
};

my $IS_PARAM = sub {
	my @S = @_;
	while(@S) {
		my $arg = pop @S;
		return 1 if UNIVERSAL::isa($arg, 'Aion::Type') && $arg->{is_param};
		push @S, @{$arg->{args}};
	}
	""
};

my $REPLACE_PARAM; $REPLACE_PARAM = sub {
	my ($arg) = @_;

	return $arg unless UNIVERSAL::isa($arg, 'Aion::Type');

	if(my $param = $arg->{is_param}) {
		return $Aion::Type::SELF->{args}->[$param - 1] if $param > 0;
		return $Aion::Type::SELF->{N} if $param == -1;
		return $Aion::Type::SELF->{M} if $param == -2;
		return $Aion::Type::SELF if $param == -256;
		return @{$Aion::Type::SELF->{args}} if $param == -1024;
		die "Parameter number invalid!";
	}

	return $arg if !$arg->{args} || !List::Util::first { UNIVERSAL::isa($_, 'Aion::Type') } @{$arg->{args}};

	$arg = bless {%$arg}, 'Aion::Type';
	$arg->{args} = [map $REPLACE_PARAM->($_), @{$arg->{args}}];
	$arg->init if $arg->{init};

	$arg
};

my $INIT_REPLACE_PARAM = sub {
	$Aion::Type::SELF->{as} = $REPLACE_PARAM->($Aion::Type::SELF->{as});
};

# Создание типа
sub subtype(@) {
	my $subtype = shift;
	my %o = @_;
	
	my ($as, $init_where, $where, $awhere, $message) = delete @o{qw/as init_where where awhere message/};
	
	die "subtype $subtype unused keys left: " . join ", ", keys %o if keys %o;
	
	die "subtype format is Name or Name[args] or Name`[args]" if $subtype !~ /^([A-Z_]\w*)(?:(\`)?\[(.*)\])?$/i;
	my ($name, $is_maybe_arg, $is_arg) = ($1, $2, $3);

	my $pkg = scalar caller;
	die "subtype $subtype: ${pkg}::$name exists!" if *{"${pkg}::$name"}{CODE};

	if($is_maybe_arg) {
		die "subtype $subtype: needs an awhere" if !$awhere;
	} else {
		die "subtype $subtype: awhere is excess" if $awhere;
	}

	my @init = $init_where? $init_where: ();
	
	my $init_types = do { given($is_arg) {
		$INIT_ARGS when /^[A-Z]\w*(,\s*[A-Z]\w*)?\.\.\.$/;
		$INIT_KW_ARGS when /^[a-z]\w*\s*=>\s*[A-Z],?\s*\.\.\.$/;
		when(/\b[A-Z]\b/) {
			my @args = split /\s*,\s*/, $is_arg;
			my @typeno = grep { $args[$_] =~ /^[A-Z]/ } 0..@args-1;
			(sub { my ($typeno) = @_; sub {
				my $args = &ARGS;
				$args->[$_] = External([$args->[$_]]) for @$typeno;
			} })->(\@typeno);
		}
	}};

	unshift @init, $init_types if $init_types;
	
	$as = External([$as]) if defined $as;
	
	unshift @init, $INIT_REPLACE_PARAM if $as && $is_arg && $IS_PARAM->($as);

	# Тут coerce - прототип - единый для всех порождаемых типов одного типа с разными аргументами
	my $type = Aion::Type->new(
		name => $name,
		coerce => [], # prototype
		test => $where // \&Aion::Type::true,
		$as? (as => $as): (),
		@init? (init => \@init): (),
		$awhere? (a_test => $awhere): (),
		$message? (message => $message): (),
	);
	
	if($is_maybe_arg) {
		$type->make_maybe_arg($pkg)
	} elsif($is_arg || @init) {
		$type->make_arg($pkg, $is_arg)
	} else {
		$type->make($pkg)
	}
}
}

sub as(@) { (as => @_) }
sub init_where(&@) { (init_where => @_) }
sub where(&@) { (where => @_) }
sub awhere(&@) { (awhere => @_) }
sub message(&@) { (message => @_) }

sub SELF() { $Aion::Type::SELF }
sub ARGS() {
	return $Aion::Type::SELF->{is_param_args} if $Aion::Type::SELF->{is_param_args};
	wantarray? @{$Aion::Type::SELF->{args}}: $Aion::Type::SELF->{args}
}
sub A() { $Aion::Type::SELF->{args}[0] }
sub B() { $Aion::Type::SELF->{args}[1] }
sub C() { $Aion::Type::SELF->{args}[2] }
sub D() { $Aion::Type::SELF->{args}[3] }

sub M() :lvalue { $Aion::Type::SELF->{M} }
sub N() :lvalue { $Aion::Type::SELF->{N} }

# Создание транслятора. У типа может быть сколько угодно трансляторов из других типов
# coerce Type, from OtherType, via {...}
sub coerce(@) {
	my ($type, %o) = @_;
	my ($from, $via) = delete @o{qw/from via/};

	die "coerce $type unused keys left: " . join ", ", keys %o if keys %o;
	die "coerce $type not Aion::Type!" unless UNIVERSAL::isa($type, "Aion::Type");
	die "coerce $type: from is'nt Aion::Type!" unless UNIVERSAL::isa($from, "Aion::Type");
	die "coerce $type: via is not subroutine!" unless ref $via eq "CODE";

	push @{$type->{coerce}}, [$from, $via];
	return;
}

sub from($) { (from => $_[0]) }
sub via(&) { (via => $_[0]) }

use constant DBL_MAX => (POSIX::DBL_MAX+0) =~ /inf/i? do {
	require Math::BigFloat;
	Math::BigFloat->new(POSIX::DBL_MAX =~ /inf/i? '1.7976931348623157e+308': POSIX::DBL_MAX)
}: POSIX::DBL_MAX;


sub _8BITS() {
	undef *_8BITS;
	require Math::BigInt;
	constant->import(_8BITS => Math::BigInt->new(8));
}

BEGIN {

subtype "Any";
	subtype "Control", as &Any;
        subtype "Union[A, B...]", as &Control,
            where { my $val = $_; any { $_->include($val) } ARGS };
        subtype "Intersection[A, B...]", as &Control,
            where { my $val = $_; all { $_->include($val) } ARGS };
		subtype "Exclude[A]", as &Control,
			where { !A->test };
		subtype "Option[A]", as &Control,
			init_where { SELF->{is_option} = 1 }
			where { A->test };
		subtype "Wantarray[A, S]", as &Control,
			init_where { SELF->{is_wantarray} = 1 }
			where { ... };

	subtype "Item", as &Any;
		sub External($) {
			local $_ = $_[0][0];
			UNIVERSAL::isa($_, 'Aion::Type')? $_:
			defined($_) && ref $_ eq ""? Object([$_]): do {
				die "Not External[${\val_to_str($_)}]" unless reftype($_) eq "CODE" || overload::Method($_, '&{}');
				Aion::Type->new(
					name => 'External',
					as => &Item,
					args => $_[0],
					test => $_,
					UNIVERSAL::can($_, 'coerce')
						? (coerce => [[&Any, (sub { my ($ex) = @_; sub { $ex->coerce } })->($_)]])
						: (),
				)
			}
		}
		subtype "Bool", as &Item, where { ref $_ eq "" and /^(1|0|)\z/ };
		subtype "BoolLike", as &Item, where {
			return 1 if overload::Method($_, 'bool');
			my $m = overload::Method($_, '0+');
			Bool()->include($m ? $m->($_) : $_) };
		subtype "Enum[e...]", as &Item,
			init_where { M = +{ map {($_ => $_)} ARGS } }
			where { exists M->{$_} };
		subtype "Undef", as &Item, where { !defined $_ };
		subtype "Maybe[A]", as &Undef | A;
		subtype "Defined", as &Item, where { defined $_ };
			subtype "Value", as &Defined, where { "" eq ref $_ };
				subtype "Version", as &Value, where { "VSTRING" eq ref \$_ };
				subtype "Str", as &Value, where { "SCALAR" eq ref \$_ };
					subtype "Uni", as &Str,	where { utf8::is_utf8($_) || /[\x80-\xFF]/a };
					subtype "Bin", as &Str, where { !utf8::is_utf8($_) && !/[\x80-\xFF]/a };
					subtype "NonEmptyStr", as &Str,	where { /\S/ };
					subtype "StartsWith[start]", as &Str,
						init_where { M = qr/^${\ quotemeta A}/ },
						where { $_ =~ M };
					subtype "EndsWith[end]", as &Str,
						init_where { N = qr/${\ quotemeta A}$/ },
						where { $_ =~ N };
					subtype "Email", as &Str, where { /@/ };
					subtype "Tel", as &Str, where { /^\+\d{7,}\z/ };
					subtype "Url", as &Str, where { /^https?:\/\// };
					subtype "Path", as &Str, where { /^\// };
					subtype "Html", as &Str, where { /^\s*<(!doctype\s+html|html)\b/i };
					subtype "StrDate", as &Str, where { /^\d{4}-\d{2}-\d{2}\z/ };
					subtype "StrDateTime", as &Str, where { /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/ };
					subtype "StrMatch[regexp]", as &Str, where { $_ =~ A };
					subtype "PackageName", as &Str, where { no utf8; use bytes; /^(?:[a-z]\w*(?:::[a-z]\w*)*)\z/ia };
						subtype "ClassName", as &PackageName, where { !!$_->can('new') };
						subtype "RoleName", as &PackageName, where { !$_->can('new') && !!(@{"$_\::ISA"} || first { *{$_}{CODE} } values %{"$_\::"}) };
					subtype "StrRat", as &Str, where { m!\s*/\s*!? &Num->include($`) && &Num->include($`): &Num->test };
					subtype "Num", as &Str, where { looks_like_number($_) && /[\dfn]\z/i };
						subtype "Int", as &Num,	where { /^[-+]?\d+\z/ };

			subtype "Ref", as &Defined, where { "" ne ref $_ };
				subtype "Tied`[class]", as &Ref,
					where { my $ref = reftype($_); !!(
						$ref eq "HASH"? tied %$_:
						$ref eq "ARRAY"? tied @$_:
						$ref eq "SCALAR"? tied $$_:
						0
					) }
					awhere { my $ref = reftype($_);
						$ref eq "HASH"? A eq ref tied %$_:
						$ref eq "ARRAY"? A eq ref tied @$_:
						$ref eq "SCALAR"? A eq ref tied $$_:
						""
					};
				subtype "LValueRef", as &Ref, where { ref $_ eq "LVALUE" };
				subtype "FormatRef", as &Ref, where { ref $_ eq "FORMAT" };
				subtype "CodeRef", as &Ref, where { ref $_ eq "CODE" };
					subtype "NamedCode[subname]", as &CodeRef, where { Sub::Util::subname($_) ~~ A };
					subtype "ProtoCode[prototype]", as &CodeRef, where { Sub::Util::prototype($_) ~~ A };
					subtype "ForwardRef", as &CodeRef, where { !subref_is_reachable($_) };
					subtype "ImplementRef", as &CodeRef, where { subref_is_reachable($_) };
					subtype "Isa[type...]", as &CodeRef,
						init_where {
						    my $pkg = caller(2);
							SELF->{args} = [ map { External([UNIVERSAL::isa($_, 'Aion::Type')? $_: $pkg->can($_)? $pkg->can($_)->(): $_]) } ARGS ];
						}
						where {
							my $subroutine = $Aion::Isa{pack "J", refaddr $_} or return "";
							my $signature = $subroutine->{signature};
							my $args = ARGS;
							return "" if @$signature != @$args;
							my $i = 0;
							for my $type (@$args) {
								return "" unless $signature->[$i++] eq $type;
							}
							1
						};
				subtype "RegexpRef", as &Ref, where { ref $_ eq "Regexp" };
				subtype "ValueRef`[A]", as &Ref,
					where { ref($_) ~~ ["SCALAR", "REF"] }
					awhere { ref($_) ~~ ["SCALAR", "REF"] && A->include($$_) };
					subtype "ScalarRef`[A]", as &ValueRef,
						where { ref $_ eq "SCALAR" }
						awhere { ref $_ eq "SCALAR" && A->include($$_) };
					subtype "RefRef`[A]", as &ValueRef,
						where { ref $_ eq "REF" }
						awhere { ref $_ eq "REF" && A->include($$_) };
				subtype "GlobRef", as &Ref, where { ref $_ eq "GLOB" };
					subtype "FileHandle", as &GlobRef,
						where { !!*$_{IO} };
				subtype "ArrayRef`[A]", as &Ref,
					where { ref $_ eq "ARRAY" }
					awhere { my $A = A; ref $_ eq "ARRAY" && all { $A->test } @$_ };
					subtype "Tuple[A...]", as &ArrayRef,
						where {
							my $k = 0;
							for my $A (ARGS) {
								return "" if $A->exclude($_->[$k++]);
							}
							$k == @$_
						};
					subtype "CycleTuple[A...]", as &ArrayRef,
						where {
							my $k = 0;
							while($k < @$_) {
								for my $A (ARGS) {
									return "" if $A->exclude($_->[$k++]);
								}
							}
							$k == @$_
						};
				subtype "HashRef`[A]", as &Ref,
					where { ref $_ eq "HASH" }
					awhere { my $A = A; ref $_ eq "HASH" && all { $A->test } values %$_ };
					subtype "Dict[k => A, ...]", as &HashRef,
						where {
							my $count = 0; my $k;
							for my $A (ARGS) {
								$k = $A, next unless ref $A;
								if(exists $_->{$k}) {
									return "" if $A->exclude($_->{$k});
									$count++;
								} else {
									return "" if !exists $A->{is_option};
								}
							}
							$count == keys %$_
						};
					subtype "Map[K, V]", as &HashRef,
						where {
							my ($K, $V) = ARGS;
							while(my ($k, $v) = each %$_) {
								return "" unless $K->include($k) && $V->include($v);
							}
							return 1;
						};
				subtype "Object`[class]", as &Ref,
					where { blessed($_) ne "" }
					awhere { blessed($_) && $_->isa(A) };
					subtype "Me", as &Object,
						init_where { SELF->{as} = Object([caller(2)]) };
					subtype "Rat", as 'Math::BigRat';
				subtype "RegexpLike", as &Ref,
					where { reftype($_) eq "REGEXP" || !!overload::Method($_, 'qr') };
				subtype "CodeLike", as &Ref,
					where { reftype($_) eq "CODE" || !!overload::Method($_, '&{}') };
				subtype "ArrayLike`[A]", as &Ref,
					where { reftype($_) eq "ARRAY" || !!overload::Method($_, '@{}') }
					awhere { &ArrayLike->test && do { my $A = A; all { $A->test } @$_ }};
					subtype "Lim[from, to?]", as &ArrayLike,
						init_where { unshift @{&ARGS}, 0 if @{&ARGS} == 1; }
						where { A <= @$_ && @$_ <= B };
				subtype "HashLike`[A]", as &Ref,
					where { reftype($_) eq "HASH" || !!overload::Method($_, "%{}") }
					awhere { &HashLike->test && do { my $A = A; all { $A->test } values %$_ }};
						subtype "HasProp[p...]", as &HashLike,
							where { my $x = $_; all { exists $x->{$_} } ARGS };
						subtype "LimKeys[from, to?]", as &HashLike,
							init_where { unshift @{&ARGS}, 0 if @{&ARGS} == 1; }
							where { A <= scalar keys %$_ && scalar keys %$_ <= B };
		
			subtype "Like", as &Str | &Object;
				subtype "HasMethods[m...]", as &Like,
					where { my $x = $_; all { $x->can($_) } ARGS };
				subtype "Overload`[m...]", as &Like,
					where { !!overload::Overloaded($_) }
					awhere { my $x = $_; all { overload::Method($x, $_) } ARGS };
				subtype "InstanceOf[class...]", as &Like, where { my $x = $_; all { $x->isa($_) } ARGS };
				subtype "ConsumerOf[role...]", as &Like, where { my $x = $_; all { $x->DOES($_) } ARGS };
				subtype "StrLike", as &Like, where { !blessed($_) or !!overload::Method($_, '""') };
					subtype "Len[from, to?]", as &StrLike,
						init_where { unshift @{&ARGS}, 0 if @{&ARGS} == 1; }
						where { A <= length($_) && length($_) <= B };
	
				subtype "NumLike", as &Like, where { looks_like_number($_) };
					sub Opened($) { Aion::Type::Lim->from(ref $_[0] eq "ARRAY"? $_[0][0]: $_[0]) };
					subtype "Range[from, to]", as &NumLike,
						init_where {
							SELF->{args}[0] = A->inc if UNIVERSAL::isa(A, 'Aion::Type::Lim');
							SELF->{args}[1] = B->dec if UNIVERSAL::isa(B, 'Aion::Type::Lim');
						}
						where { A <= $_ && $_ <= B };
						subtype "Float", as Range([-(POSIX::FLT_MAX), POSIX::FLT_MAX]);
						subtype "Double", as Range([-(DBL_MAX), DBL_MAX]);
						subtype "Bytes[n]", as Range([]),
							init_where {
								my $N = 1 << (8 * A - 1);
								$N = 1 << (_8BITS * A - 1) if $N eq 0;
								SELF->{as} = Range([-$N, $N-1]);
							};
						subtype "PositiveBytes[n]", as Range([]),
							init_where {
								my $M = (1 << (8*A));
								$M = (1 << (_8BITS*A)) if $M eq 0;
								SELF->{as} = Range([0, $M-1]);
							};

	coerce &Str => from &Undef => via { "" };
	coerce &Int => from &Num => via { int($_+($_ < 0? -.5: .5)) };
	coerce &Bool => from &Any => via { !!$_ };

	subtype 'Join[separator]', as &Str;
	coerce &Join, from &ArrayRef, via { join A, @$_ };

	subtype 'Split[separator]', as &ArrayRef;
	coerce &Split, from &Str, via { [split A, $_] };

	coerce &Rat => from &StrRat => via { Math::BigRat->new($_) };

	subtype "PositiveNum", as &Num & Range([0, 'Inf']);
	subtype "PositiveInt", as &Int & Range([0, 'Inf']);
	subtype "Nat", as &Int & Range([1, 'Inf']);

};

$_->keyfn(\&Aion::Type::typed_sorted_args_key) for Union[], Intersection[];
(Enum[])->keyfn(\&Aion::Type::sorted_args_key);

%Aion::Type::range_lbound = map { (Scalar::Util::refaddr $_->{coerce} => $_->{name} eq 'Range'? '-Inf': 0) } Range[], Lim[], LimKeys[], Len[];

1;
