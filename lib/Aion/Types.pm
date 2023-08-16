package Aion::Types;
# Типы-валидаторы для Aion

use common::sense;
use Aion::Type;
use Attribute::Handlers;
use Scalar::Util qw//;
use List::Util qw/all any/;
use Exporter qw/import/;

our @EXPORT = our @EXPORT_OK = qw/
    subtype as init_where where awhere message
    SELF ARGS A B C D
    coerce from via

    Any
        Control
            Union
            Intersection
            Exclude
            Option
            Slurp

        Array
            ATuple
            ACycleTuple
        Hash
            HMap
        Item
            Bool
            Enum
            Maybe
            Undef
            Defined
                Value
                    Version
                    Str
                        Uni
                        Bin
                        NonEmptyStr
                        Email
                        Tel
                        Url
                        Path
                        Html
                        StrDate
                        StrDateTime
                        StrMatch
                        ClassName
                        RoleName
                        Numeric
                            Num
                                PositiveNum
                                Float
								Double
                                Range
                                Int
                                    PositiveInt
                                    Nat
                Ref
                    Tied
                    LValueRef
                    FormatRef
                    CodeRef
                    RegexpRef
                    ScalarRef
                    RefRef
                    GlobRef
                    ArrayRef
                    HashRef
                    Object
                    Map
                    Tuple
                    CycleTuple
                    Dict
					HasProp
                Like
                    HasMethods
                    Overload
                    InstanceOf
                    ConsumerOf
					StrLike
					RegexpLike
					CodeLike
					ArrayLike
					HashLike
/;


sub UNIVERSAL::Isa : ATTR(CODE) {
    my ($pkg, $symbol, $referent, $attr, $data, $phase, $file, $line) = @_;
    my $args_of_meth = "Arguments of method `" . *{$symbol}{NAME} . "`";
    my $returns_of_meth = "Returns of method " . *{$symbol}{NAME} . "`";

	my @signature = map { ref($_)? $_: eval("package $pkg { $_ }") || die } @$data;

    my $returns = Aion::Types::Tuple([pop @signature]);
    my $args = Aion::Types::Tuple(\@signature);

    *$symbol = sub {
        $args->validate(\@_, $args_of_meth);
        wantarray? do {
            my @returns = $referent->(@_);
            $returns->validate(\@returns, $returns_of_meth);
            @returns
        }: do {
            my $return = $referent->(@_);
            $returns->validate([$return], $returns_of_meth);
            $return
        }
    }
}

my $SUB1 = sub {1};

# Создание типа
sub subtype(@) {
	my $save = my $name = shift;
	my %o = @_;
	
	my ($as, $init_where, $where, $awhere, $message) = @o{qw/as init_where where awhere message/};

	my $is_maybe_arg; my $is_arg;
	$name =~ s/(`?)(\[.*)/ $is_maybe_arg = $1; $is_arg = $2; ''/e;

	if($is_maybe_arg) {
		die "subtype $save: needs a awhere" if !$awhere;
	} else {
		die "subtype $save: awhere is excess" if $awhere;
	}
	
	die "subtype $save: needs a where" if $is_arg && !$where;

	if($as && $as->{test} != $SUB1) {
		if(!$where && !$awhere) {
			$where = (sub { my ($as) = @_; sub { $as->test } })->($as);
		} else {
			$where = (sub { my ($as, $where) = @_; sub { $as->test && $where->(@_) } })->($as, $where) if $where;
			$awhere = (sub { my ($as, $awhere) = @_; sub { $as->test && $awhere->(@_) } })->($as, $awhere) if $awhere;
		}
	}

	my $type = Aion::Type->new(name => $name);
	
	$type->{detail} = $message if $message;
	$type->{init} = $init_where if $init_where;

	if($is_maybe_arg) {
		$type->{test} = $where;
		$type->{a_test} = $awhere;
		$type->make_maybe_arg(scalar caller)
	} elsif($is_arg) {
		$type->{test} = $where;
		$type->make_arg(scalar caller)
	} else {
		$type->{test} = $where // $SUB1;
		$type->make(scalar caller)
	}
}

sub as($) { (as => @_) }
sub init_where(&@) { (init_where => @_) }
sub where(&@) { (where => @_) }
sub awhere(&@) { (awhere => @_) }
sub message(&@) { (message => @_) }

sub SELF() { $Aion::Type::SELF }
sub ARGS() { wantarray? @{$Aion::Type::SELF->{args}}: $Aion::Type::SELF->{args} }
sub A() { $Aion::Type::SELF->{args}[0] }
sub B() { $Aion::Type::SELF->{args}[1] }
sub C() { $Aion::Type::SELF->{args}[2] }
sub D() { $Aion::Type::SELF->{args}[3] }

# Создание транслятора. У типа может быть сколько угодно трансляторов из других типов
# coerce Type, from OtherType, via {...}
sub coerce(@) {
	my ($type, %o) = @_;
	my ($from, $via) = @o{qw/from via/};

	die "coerce $type not Aion::Type!" unless UNIVERSAL::isa($from, "Aion::Type");
	die "coerce $type: from is'nt Aion::Type!" unless UNIVERSAL::isa($from, "Aion::Type");
	die "coerce $type: via is not subroutine!" unless ref $via eq "CODE";

	push @{$type->{coerce}}, [$from, $via];
	return;
}

sub from($) { (from => $_[0]) }
sub via(&) { (via => $_[0]) }

# $types - arrayref of Aion::Type
# $array - arrayref
# $from - from index
# $times - 0 - 0+, 1 - 1, 2 - 1+
# returns increment if true or undef if false
sub _tuple {
	my ($types, $array, $from) = @_;
	my $j = 0; my $i = $from;
	for(; $j < @$types; $j++) {
		my $item = $array->[$i];
		my $type = $types->[$j];

		if($type->{is_slurp}) {
			my ($name, $args) = @{$type->{args}[0]}{qw/name args/};
			if($name eq "ArrayRef") {
				$i++ while $i < @$array && $args->[0]->include($array->[$i]);
			}
			elsif($name eq "Tuple") {
				my $ret = _tuple($args, $array, $i);
				return undef unless defined $ret;
				$i = $ret;
			}
			elsif($name eq "CycleTuple") {
				my $ret = _tuple($args, $array, $i);
				return undef unless defined $ret;
				$i = $ret;
				$i = $ret while defined($ret = _tuple($args, $array, $i));
			} else {
				die "Slurp[$name] is'nt valid in array context!";
			}
		} else {
			return undef if $type->exclude($item);
			$i++;
		}
	}

	return $i;
}

# Проверяет, что есть соответствующие ключи с типами и считает их
sub _dict {
	my ($types, $hash) = @_;
	my $count = 0;
	for(my $i=0; $i<@$types; $i+=2) {
		if(UNIVERSAL::isa($types->[$i], 'Aion::Type')) {
			die "No key for $types->[$i]->{name}!" unless exists $types->[$i]->{is_slurp};
			my ($name, $args) = @{$types->[$i]{args}[0]}{qw/name args/};

			if($name eq "Dict") {
				my $ret = _dict($args, $hash);
				return undef unless defined $ret;
				$count += $ret;
			}
			else {
				die "Slurp[$name] is'nt in hash content!"
			}
		}
		else {
			my ($k, $T) = @$types[$i, $i+1];
			if(exists $hash->{$k}) {
				return undef if $T->exclude($hash->{$k});
			} else {
				return undef if !exists $T->{$k}->{is_option};
			}

			$count++;
		}
	}
}

BEGIN {

subtype "Any";
	subtype "Control", as &Any;
		subtype "Union[A, B...]", as &Control,
			where { my $val = $_; any { $_->include($val) } ARGS };
		subtype "Intersection[A, B...]", as &Control,
			where { my $val = $_; all { $_->include($val) } ARGS };
		subtype "Exclude[A, B...]", as &Control,
			where { my $val = $_; !any { $_->include($val) } ARGS };
		subtype "Option[A]", as &Control,
			init_where {
				SELF->{is_option} = 1;
				Tuple([Object(["Aion::Type"])])->validate(scalar ARGS, "Option[A]")
			}
			where { A->test };
		subtype "Slurp[A]", as &Control,
			init_where {
				SELF->{is_slurp} = 1;
				Tuple([Object(["Aion::Type"])])->validate(scalar ARGS, "Slurp[A]")
			}
			where { ... };

	subtype "Array`[A]", as &Any,
		where { $_->[1] = @{$_->[0]}; 1 }
		awhere {
			my ($i, $a) = @$_; my ($A) = @_;
			while($i<@$a) { $i++ if $A->include( $a->[$i] ) }
			$_->[0] = $i;
			return 1;
		};

		subtype "ATuple[A...]", as &Array,
			init_where { ArrayRef([Object(['Aion::Type'])])->validate(scalar ARGS, "ATuple[A...]") }
			where {
				my $T = ARGS;
				my ($i, $a) = @$_;
				my $j = 0;
				for(; $i < @$a && $j < @$T; $j++, $i++) { 
					last unless $T->[$j]->include($a->[$i]);
				}

				$_->[0] = $i, return 1 if $j == @$T;

				return 0;
			};

		subtype "ACycleTuple[A...]", as &Array,
			init_where { ArrayRef([Object(['Aion::Type'])])->validate(scalar ARGS, "ACycleTuple[A...]") }
			where {
				my $A = ATuple $_[1];
				$A->test or return 0;
				while($A->test) {}
				return 1;
			};

	subtype "Hash`[A]", as &Any,
		where { ACycleTuple([&Str, &Item])->test }
		awhere { ACycleTuple([&Str, $_[0]])->test };

		subtype "HMap[K, V]", as &Any,
		where { ACycleTuple([@_])->test };

	subtype "Item", as &Any;
		subtype "Bool", as &Item, where { ref $_ eq "" and /^(1|0|)\z/ };
		subtype "Enum[A...]", as &Item, where { $_ ~~ ARGS };
		subtype "Maybe[A]", as &Item, where { !defined($_) || A->test };
		subtype "Undef", as &Item, where { !defined $_ };
		subtype "Defined", as &Item, where { defined $_ };
			subtype "Value", as &Defined, where { "" eq ref $_ };
				subtype "Version", as &Value, where { "VSTRING" eq ref \$_ };
				my $StrInit = sub { if(@{&ARGS} == 1) { SELF->{min} = 0; SELF->{max} = A } else { SELF->{min} = A; SELF->{max} = B } };
				subtype "Str`[A, B?]", as &Value,
					where { "SCALAR" eq ref \$_ },
					init_where { $StrInit->() }
					awhere { &Str->test && SELF->{min} <= length($_) && length($_) <= SELF->{max} };
					subtype "Uni", as &Str, where { utf8::is_utf8($_) || !/[\x80-\xFF]/a };
					subtype "Bin`[A, B?]", as &Str,
						where { !utf8::is_utf8($_) }
						init_where { $StrInit->() }
						awhere { &Bin->test && SELF->{min} <= length($_) && length($_) <= SELF->{max} };
					subtype "NonEmptyStr`[A, B?]", as &Str,
						where { /\S/ }
						init_where { $StrInit->() }
						awhere { /\S/ && SELF->{min} <= length($_) && length($_) <= SELF->{max} };
					subtype "Email", as &Str, where { /@/ };
					subtype "Tel", as &Str, where { /^\+\d{7,}/ };
					subtype "Url", as &Str, where { /^https?:\/\// };
					subtype "Path", as &Str, where { /^\// };
					subtype "Html", as &Str, where { /^\s*<(!doctype|html)\b/i };
					subtype "StrDate", as &Str, where { /^\d{4}-\d{2}-\d{2}\z/ };
					subtype "StrDateTime", as &Str, where { /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/ };
					subtype "StrMatch[qr/.../]", as &Str, where { $_ =~ A };
					
					subtype "ClassName", as &Str, where { $_->can('new') };
					subtype "RoleName", as &Str, where { $_->can('requires') };
					subtype "Numeric", as &Str, where { Scalar::Util::looks_like_number($_) };
						subtype "Num", as &Numeric, where { /\d\z/ };
							subtype "PositiveNum", as &Num, where { $_ >= 0 };
							subtype "Float", as &Num, where { -3.402823466E+38 <= $_ <= 3.402823466E+38 };
							subtype "Double", as &Num, where { -1.7976931348623158e+308 <= $_ <= 1.7976931348623158e+308 };
							subtype "Range[from, to]", as &Num, where { A <= $_ <= B };
							subtype "Int`[N]", as &Num,
								where { /^-?\d+\z/ }
								init_where {
									my $A = A;
									my $N = 1 << (8*$A - 1);
									$N = 1 << (8*Math::BigInt->new($A)-1) unless $N;
									SELF->{min} = -$N;
									SELF->{max} = $N-1;
								}
								awhere { /^-?\d+\z/ && SELF->{min} <= $_ && $_ <= SELF->{max} };
								subtype "PositiveInt`[N]", as &Int,
									where { $_ >= 0 }
									init_where {
										my $A = A;
										my $N = 1 << (8*$A);
										$N = 1 << (8*Math::BigInt->new($A)) unless $N;
										SELF->{min} = 0;
										SELF->{max} = $N-1;
									}
									awhere { SELF->{min} <= $_ && $_ <= SELF->{max} };
								subtype "Nat`[N]", as &Int, 
									where { $_ > 0 }
									init_where {
										my $A = A;
										my $N = 1 << (8*$A);
										$N = 1 << (8*Math::BigInt->new($A)) unless $N;
										SELF->{min} = 1;
										SELF->{max} = $N-1;
									}
									awhere { SELF->{min} <= $_ && $_ <= SELF->{max} };

			subtype "Ref", as &Defined, where { "" ne ref $_ };
				subtype "Tied`[A]", as &Ref,
					where { my $ref = Scalar::Util::reftype($_); !!(
						$ref eq "HASH"? tied %$_:
						$ref eq "ARRAY"? tied @$_:
						$ref eq "SCALAR"? tied $$_:
						0
					) }
					awhere { my $ref = Scalar::Util::reftype($_);
						$ref eq "HASH"? A eq tied %$_:
						$ref eq "ARRAY"? A eq tied @$_:
						$ref eq "SCALAR"? A eq tied $$_:
						""
					};
				subtype "LValueRef", as &Ref, where { ref $_ eq "LVALUE" };
				subtype "FormatRef", as &Ref, where { ref $_ eq "FORMAT" };
				subtype "CodeRef", as &Ref, where { ref $_ eq "CODE" };
				subtype "RegexpRef", as &Ref, where { ref $_ eq "Regexp" };
				subtype "ScalarRef`[A]", as &Ref,
					where { ref $_ eq "SCALAR" }
					awhere { ref $_ eq "SCALAR" && A->include($$_) };
				subtype "RefRef`[A]", as &Ref,
					where { ref $_ eq "REF" }
					awhere { ref $_ eq "REF" && A->include($$_) };
				subtype "GlobRef", as &Ref,
					where { ref $_ eq "GLOB" };
				subtype "ArrayRef`[A]", as &Ref,
					where { ref $_ eq "ARRAY" }
					awhere { my $A = A; ref $_ eq "ARRAY" && all { $A->test } @$_ };
				subtype "HashRef`[H]", as &Ref,
					where { ref $_ eq "HASH" }
					awhere { my $A = A; ref $_ eq "HASH" && all { $A->test } values %$_ };
				subtype "Object`[O]", as &Ref,
					init_where { eval "require " . A if defined A }
					where { Scalar::Util::blessed($_) ne "" }
					awhere { UNIVERSAL::isa($_, A) };
				subtype "HasProp[p...]", as &Ref,
					where { my $x = $_; all { exists $x->{$_} } ARGS };

				subtype "Map[K, V]", as &HashRef,
					where {
						my ($K, $V) = ARGS;
						while(my ($k, $v) = each %$_) {
							return "" unless $K->include($k) && $V->include($v);
						}
						return 1;
					};


				my $tuple_args = ArrayRef([Object(['Aion::Type'])]);
				subtype "Tuple[A...]", as &ArrayRef,
					init_where { $tuple_args->validate(scalar ARGS, "Arguments Tuple[A...]") }
					where {
						my $ret = _tuple(scalar ARGS, $_, 0);
						return "" unless defined $ret;
						return 1;
					};
				subtype "CycleTuple[A...]", as &ArrayRef,
					init_where { $tuple_args->validate(scalar ARGS, "Arguments CycleTuple[A...]") }
					where {
						my $args = ARGS;
						for(my $i = 0, my $ret; $i < @$_; $i = $ret) {
							$ret = _tuple($args, $_, $i);
							return "" unless defined $ret;
						}
						return 1;
					};

				my $dict_args = CycleTuple([&Str => Object(['Aion::Type'])]) | Object(['Aion::Type']) & HasProp([qw/is_slurp/]);

				subtype "Dict[k => A, ...]", as &HashRef,
					init_where {
						$dict_args->validate(scalar ARGS, "Dict[k => A, ...]");
					}
					where {
						my $count = _dict(scalar ARGS, $_);
						return "" unless defined $count;
						return "" unless $count == keys %$_;
						return 1;
					};

			subtype "Like", as (&Str | &Object);
				subtype "HasMethods[m...]", as &Like,
					where { my $x = $_; all { $x->can($_) } @{$_[1]} };
				subtype "Overload`[m...]", as &Like,
					where { !!overload::Overloaded($_) }
					awhere { my $x = $_; all { overload::Method($x, $_) } ARGS };

				subtype "InstanceOf[A...]", as &Like, where { my $x = $_; all { $x->isa($_) } ARGS };
				subtype "ConsumerOf[A...]", as &Like, where { my $x = $_; all { $x->can("does") && $x->does($_) } ARGS };

			subtype "StrLike", as (&Str | Overload(['""']));
			subtype "RegexpLike", as (&RegexpRef | Overload(['qr']));
			subtype "CodeLike", as (&CodeRef | Overload(['&{}']));
			subtype "ArrayLike`[A]", as &Ref,
				where { Scalar::Util::reftype($_) eq "ARRAY" || overload::Method($_, '@{}') }
				awhere { &ArrayLike->test && do { my $A = A; all { $A->test } @$_ }};
			subtype "HashLike`[A]", as &Ref,
				where { Scalar::Util::reftype($_) eq "HASH" || overload::Method($_, "%{}") }
				awhere { &HashLike->test && do { my $A = A; all { $A->test } values %$_ }};

	coerce &Str => from &Undef => via { "" };
};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Types is library of validators. And it makes new validators.

=head1 SYNOPSIS

	use Aion::Types;
	
	BEGIN {
	    subtype SpeakOfKitty => as StrMatch[qr/\bkitty\b/i],
	        message { "Speak is'nt included kitty!" };
	}
	
	"Kitty!" ~~ SpeakOfKitty # -> 1
	"abc" ~~ SpeakOfKitty 	 # -> ""
	
	eval { SpeakOfKitty->validate("abc", "This") }; "$@" # ~> Speak is'nt included kitty!
	
	
	BEGIN {
		subtype IntOrArrayRef => as (Int | ArrayRef);
	}
	
	[] ~~ IntOrArrayRef  # -> 1
	35 ~~ IntOrArrayRef  # -> 1
	"" ~~ IntOrArrayRef  # -> ""
	
	
	coerce IntOrArrayRef, from Num, via { int($_ + .5) };
	
	IntOrArrayRef->coerce(5.5) # => 6

=head1 DESCRIPTION

This modile export subroutines:

=over

=item * subtype, as, init_where, where, awhere, message — for create validators.

=item * SELF, ARGS, A, B, C, D — for use in validators has arguments.

=item * coerce, from, via — for create coerce, using for translate values from one class to other class.

=back

Hierarhy of validators:

	Any
		Control
			Union[A, B...]
			Intersection[A, B...]
			Exclude[A, B...]
			Option[A]
			Slurp[A]
		Array`[A]
			ATuple[A...]
			ACycleTuple[A...]
		Hash`[A]
			HMap[K, V]
		Item
			Bool
			Enum[A...]
			Maybe[A]
			Undef
			Defined
				Value
					Version
					Str`[A, B?]
						Uni
						Bin`[A, B?]
						NonEmptyStr`[A, B?]
						Email
						Tel
						Url
						Path
						Html
						StrDate
						StrDateTime
						StrMatch[qr/.../]
						ClassName[A]
						RoleName[A]
						Numeric
							Num
								PositiveNum
								Float
								Range[from, to]
								Int`[N]
									PositiveInt`[N]
									Nat`[N]
				Ref
					Tied`[A]
					LValueRef
					FormatRef
					CodeRef
					RegexpRef
					ScalarRef`[A]
					RefRef`[A]
					GlobRef`[A]
					ArrayRef`[A]
					HashRef`[H]
					Object`[O]
					Map[K, V]
					Tuple[A...]
					CycleTuple[A...]
					Dict[k => A, ...]
				Like
					HasMethods[m...]
					Overload`[m...]
					InstanceOf[A...]
					ConsumerOf[A...]
				StrLike
				RegexpLike
				CodeLike
				ArrayLike`[A]
				HashLike`[A]

=head1 TYPES

=head2 Any

Top-level type in the hierarchy. Match all.

=head2 Control

Top-level type in the hierarchy constructors new types from any types.

=head2 Union[A, B...]

Union many types.

	33  ~~ Union[Int, Ref]    # -> 1
	[]  ~~ Union[Int, Ref]    # -> 1
	"a" ~~ Union[Int, Ref]    # -> ""

=head2 Intersection[A, B...]

Intersection many types.

	15 ~~ Intersection[Int, StrMatch[/5/]]    # -> 1

=head2 Exclude[A, B...]

Exclude many types.

	-5  ~~ Exclude[PositiveInt]    # -> 1
	"a" ~~ Exclude[PositiveInt]    # -> 1
	5   ~~ Exclude[PositiveInt]    # -> ""

=head2 Option[A]

The optional keys in the C<Dict>.

	{a=>55} ~~ Dict[a=>Int, b => Option[Int]] # -> 1
	{a=>55, b=>31} ~~ Dict[a=>Int, b => Option[Int]] # -> 1

=head2 Slurp[A]

It extends the C<Dict> other dictionaries, and C<Tuple> and C<CycleTuple> extends other tuples and arrays.

	{a => 1, b => 3.14} ~~ Dict[a => Int, Slurp[ Dict[b => Num] ] ]  # -> 1
	
	[3.3, 3.3] ~~ Tuple[Num, Slurp[ ArrayRef[Int] ], Num ] # -> 1
	[3.3, 1,2,3, 3.3] ~~ Tuple[Num, Slurp[ ArrayRef[Int] ], Num ] # -> 1
	
	

=head2 Array`[A]

It use for check what the subroutine return array.

	sub array123: Isa(Int => Array[Int]) {
		my ($n) = @_;
		return $n, $n+1, $n+2;
	}
	
	[ array123(1) ]		# --> [2,3,4]
	
	eval { array123(1.1) }; # ~> 1
	

=head2 ATuple[A...]

=head2 ACycleTuple[A...]

=head2 Hash`[A]

=head2 HMap[K, V]

C<HMap[K, V]> is equivalent C<ACycleTuple[K, V]>.

=head2 Item

Top-level type in the hierarchy scalar types.

=head2 Bool

C<1> is true. C<0>, C<""> or C<undef> is false.

	1 ~~ Bool     # -> 1
	0 ~~ Bool     # -> 1
	undef ~~ Bool # -> 1
	"" ~~ Bool    # -> 1
	
	2 ~~ Bool     # -> ""

=head2 Enum[A...]

Enumerate values.

	3 ~~ Enum[1,2,3]        	# -> 1
	"cat" ~~ Enum["cat", "dog"] # -> 1
	4 ~~ Enum[1,2,3]        	# -> ""

=head2 Maybe[A]

C<undef> or type in C<[]>.

	undef ~~ Maybe[Int]    # -> 1
	4 ~~ Maybe[Int]        # -> 1
	"" ~~ Maybe[Int]       # -> ""

=head2 Undef

C<undef> only.

	undef ~~ Undef    # -> 1
	0 ~~ Undef        # -> ""

=head2 Defined

All exclude C<undef>.

	\0 ~~ Defined       # -> 1
	undef ~~ Defined    # -> ""

=head2 Value

Defined unreference values.

	3 ~~ Value        # -> 1
	\3 ~~ Value       # -> ""
	undef ~~ Value    # -> ""

=head2 Version

Perl versions.

	1.1.0 ~~ Version    # -> 1
	v1.1.0 ~~ Version   # -> 1
	1.1 ~~ Version      # -> ""
	"1.1.0" ~~ Version  # -> ""

=head2 Str`[A, B?]

Strings, include numbers.
It maybe define maximal, or minimal and maximal length.

	1.1 ~~ Str         # -> 1
	"" ~~ Str          # -> 1
	1.1.0 ~~ Str       # -> ""
	"1234" ~~ Str[3]   # -> ""
	"123" ~~ Str[3]    # -> 1
	"12" ~~ Str[3]     # -> 1
	"" ~~ Str[1, 2]    # -> ""
	"1" ~~ Str[1, 2]   # -> 1
	"12" ~~ Str[1, 2]   # -> 1
	"123" ~~ Str[1, 2]   # -> ""

=head2 Uni

Unicode strings: with utf8-flag or characters with numbers less then 128.

	"↭" ~~ Uni    # -> 1
	123 ~~ Uni    # -> 1
	do {no utf8; "↭" ~~ Uni}    # -> ""

=head2 Bin`[A, B?]

Binary strings: without utf8-flag.
It maybe define maximal, or minimal and maximal length.

	123 ~~ Bin    # -> 1
	"z" ~~ Bin    # -> 1
	do {no utf8; "↭" ~~ Bin }   # -> 1

=head2 NonEmptyStr`[A, B?]

String with one or many non-space characters.

	" " ~~ NonEmptyStr        # -> ""
	" S " ~~ NonEmptyStr      # -> 1
	" S " ~~ NonEmptyStr[2]   # -> ""
	" S" ~~ NonEmptyStr[2]    # -> 1
	" S" ~~ NonEmptyStr[1,2]  # -> 1
	" S " ~~ NonEmptyStr[1,2] # -> ""
	"S" ~~ NonEmptyStr[2,3]   # -> ""

=head2 Email

Strings with C<@>.

	'@' ~~ Email      # -> 1
	'a@a.a' ~~ Email  # -> 1
	'a.a' ~~ Email    # -> ""

=head2 Tel

Format phones is plus sign and one or many digits.

	"+1" ~~ Tel    # -> 1
	"+ 1" ~~ Tel    # -> ""
	"+1 " ~~ Tel    # -> ""

=head2 Url

Web urls is string with prefix http:// or https://.

	"http://" ~~ Url    # -> 1
	"http:/" ~~ Url    # -> ""

=head2 Path

The paths starts with a slash.

	"/" ~~ Path     # -> 1
	"/a/b" ~~ Path  # -> 1
	"a/b" ~~ Path   # -> ""

=head2 Html

The html starts with a C<< E<lt>!doctype >> or C<< E<lt>html >>.

	"<HTML" ~~ Html            # -> 1
	" <html" ~~ Html           # -> 1
	" <!doctype html>" ~~ Html # -> 1
	" <html1>" ~~ Html         # -> ""

=head2 StrDate

The date is format C<yyyy-mm-dd>.

	"2001-01-12" ~~ StrDate    # -> 1
	"01-01-01" ~~ StrDate    # -> ""

=head2 StrDateTime

The dateTime is format C<yyyy-mm-dd HH:MM:SS>.

	"2012-12-01 00:00:00" ~~ StrDateTime     # -> 1
	"2012-12-01 00:00:00 " ~~ StrDateTime    # -> ""

=head2 StrMatch[qr/.../]

Match value with regular expression.

	' abc ' ~~ StrMatch[qr/abc/]    # -> 1
	' abbc ' ~~ StrMatch[qr/abc/]   # -> ""

=head2 ClassName

Classname is the package with method C<new>.

	'Aion::Type' ~~ ClassName     # -> 1
	'Aion::Types' ~~ ClassName    # -> ""

=head2 RoleName

Rolename is the package with subroutine C<requires>.

	package ExRole {
		sub requires {}
	}
	
	'ExRole' ~~ RoleName    	# -> 1
	'Aion::Type' ~~ RoleName    # -> ""

=head2 Numeric

Test scalar with C<Scalar::Util::looks_like_number>. Maybe spaces on end.

	6.5 ~~ Numeric       # -> 1
	6.5e-7 ~~ Numeric    # -> 1
	"6.5 " ~~ Numeric    # -> 1
	"v6.5" ~~ Numeric    # -> ""

=head2 Num

The numbers.

	-6.5 ~~ Num       # -> 1
	6.5e-7 ~~ Num    # -> 1
	"6.5 " ~~ Num    # -> ""

=head2 PositiveNum

The positive numbers.

	 ~~ PositiveNum    # -> 1
	 ~~ PositiveNum    # -> ""

=head2 Float

The machine float number is 4 bytes.

	-4.8 ~~ Float    				# -> 1
	-3.402823466E+38 ~~ Float    	# -> 1
	+3.402823466E+38 ~~ Float    	# -> 1
	-3.402823467E+38 ~~ Float       # -> ""

=head2 Double

The machine float number is 8 bytes.

	-4.8 ~~ Double    					# -> 1
	-1.7976931348623158e+308 ~~ Double  # -> 1
	+1.7976931348623158e+308 ~~ Double  # -> 1
	-1.7976931348623159e+308 ~~ Double # -> ""

=head2 Range[from, to]

Values between C<from> and C<to>.

	1 ~~ Range[1, 3]    # -> 1
	2.5 ~~ Range[1, 3]  # -> 1
	3 ~~ Range[1, 3]    # -> 1
	3.1 ~~ Range[1, 3]  # -> ""
	0.9 ~~ Range[1, 3]  # -> ""
	"b" ~~ Range["a", "c"]  # -> 1
	"bc" ~~ Range["a", "c"]  # -> 1
	"d" ~~ Range["a", "c"]  # -> ""

=head2 Int`[N]

Integers.

	123 ~~ Int    # -> 1
	-12 ~~ Int    # -> 1
	5.5 ~~ Int    # -> ""

C<N> - the number of bytes for limit.

	127 ~~ Int[1]    # -> 1
	128 ~~ Int[1]    # -> ""
	
	-127 ~~ Int[1]    # -> 1
	-128 ~~ Int[1]    # -> ""

=head2 PositiveInt`[N]

Positive integers.

	+0 ~~ PositiveInt    # -> 1
	-0 ~~ PositiveInt    # -> 1
	55 ~~ PositiveInt    # -> 1
	-1 ~~ PositiveInt    # -> ""

C<N> - the number of bytes for limit.

	255 ~~ PositiveInt[1]    # -> 1
	256 ~~ PositiveInt[1]    # -> ""

=head2 Nat`[N]

Integers 1+.

	1 ~~ Nat    # -> 1
	0 ~~ Nat    # -> ""



	255 ~~ Nat[1]    # -> 1
	256 ~~ Nat[1]    # -> ""

=head2 Ref

The value is reference.

	\1 ~~ Ref    # -> 1
	1 ~~ Ref     # -> ""

=head2 Tied`[A]

The reference on the tied variable.

	package A {
	
	}
	
	tie my %a, "A";
	my %b;
	
	\%a ~~ Tied    # -> 1
	\%b ~~ Tied    # -> ""

=head2 LValueRef

The function allows assignment.

	package As {
		sub x : lvalue {
			shift->{x};
		}
	}
	
	my $x = bless {}, "As";
	$x->x = 10;
	
	$x->x # => 10
	$x->x ~~ LValueRef    # -> 1
	
	sub abc: lvalue { $_ }
	
	abc() = 12;
	$_ # => 12
	\(&abc) ~~ LValueRef	# -> 1
	
	\1 ~~ LValueRef	# -> ""
	
	my $x = "abc";
	substr($x, 1, 1) = 10;
	
	$x # => a10c
	
	LValueRef->include(\substr($x, 1, 1))	# => 1

=head2 FormatRef

The format.

	format EXAMPLE_FMT =
	@<<<<<<   @||||||   @>>>>>>
	"left",   "middle", "right"
	.
	
	*EXAMPLE_FMT{FORMAT} ~~ FormatRef   # -> 1
	\1 ~~ FormatRef    			# -> ""

=head2 CodeRef

Subroutine.

	sub {} ~~ CodeRef    # -> 1
	\1 ~~ CodeRef        # -> ""

=head2 RegexpRef

The regular expression.

	qr// ~~ RegexpRef    # -> 1
	\1 ~~ RegexpRef    	 # -> ""

=head2 ScalarRef`[A]

The scalar.

	\12 ~~ ScalarRef     		# -> 1
	\\12 ~~ ScalarRef    		# -> ""
	\-1.2 ~~ ScalarRef[Num]     # -> 1

=head2 RefRef`[A]

The ref as ref.

	\\1 ~~ RefRef    # -> 1
	\1 ~~ RefRef     # -> ""
	\\1.3 ~~ RefRef[ScalarRef[Num]]    # -> 1

=head2 GlobRef

The global.

	\*A::a ~~ GlobRef    # -> 1
	*A::a ~~ GlobRef     # -> ""

=head2 ArrayRef`[A]

The arrays.

	[] ~~ ArrayRef    # -> 1
	{} ~~ ArrayRef    # -> ""
	[] ~~ ArrayRef[Num]    # -> 1
	[1, 1.1] ~~ ArrayRef[Num]    # -> 1
	[1, undef] ~~ ArrayRef[Num]    # -> ""

=head2 HashRef`[H]

The hashes.

	{} ~~ HashRef    # -> 1
	\1 ~~ HashRef    # -> ""
	
	{x=>1, y=>2}  ~~ HashRef[Int]    # -> 1
	{x=>1, y=>""} ~~ HashRef[Int]    # -> ""

=head2 Object`[O]

The blessed values.

	bless(\1, "A") ~~ Object    # -> 1
	\1 ~~ Object			    # -> ""
	
	bless(\1, "A") ~~ Object["A"]   # -> 1
	bless(\1, "A") ~~ Object["B"]   # -> ""

=head2 Map[K, V]

As C<HashRef>, but has type for keys also.

	{} ~~ Map[Int, Int]    # -> 1
	{5 => 3} ~~ Map[Int, Int]    # -> 1
	{5.5 => 3} ~~ Map[Int, Int]    # -> ""
	{5 => 3.3} ~~ Map[Int, Int]    # -> ""

=head2 Tuple[A...]

The tuple.

	["a", 12] ~~ Tuple[Str, Int]    # -> 1
	["a", 12, 1] ~~ Tuple[Str, Int]    # -> ""
	["a", 12.1] ~~ Tuple[Str, Int]    # -> ""

=head2 CycleTuple[A...]

The tuple one or more times.

	["a", -5] ~~ CycleTuple[Str, Int]    # -> 1
	["a", -5, "x"] ~~ CycleTuple[Str, Int]    # -> ""
	["a", -5, "x", -6] ~~ CycleTuple[Str, Int]    # -> 1
	["a", -5, "x", -6.2] ~~ CycleTuple[Str, Int]    # -> ""

=head2 Dict[k => A, ...]

The dictionary.

	{a => -1.6, b => "abc"} ~~ Dict[a => Num, b => Str]    # -> 1
	{a => -1.6, b => "abc", c => 3} ~~ Dict[a => Num, b => Str]    # -> 1
	{a => -1.6} ~~ Dict[a => Num, b => Str]    # -> 1

=head2 HasProp[p...]

The hash has properties.

	{a => 1, b => 2, c => 3} ~~ HasProp[qw/a b/]    # -> 1
	{a => 1, b => 2} ~~ HasProp[qw/a b/]    # -> 1
	{a => 1, c => 3} ~~ HasProp[qw/a b/]    # -> ""

=head2 Like

The object or string.

	"" ~~ Like    	# -> 1
	1 ~~ Like    	# -> 1
	bless({}, "A") ~~ Like    # -> 1
	bless([], "A") ~~ Like    # -> 1
	bless(\"", "A") ~~ Like    # -> 1
	\1 ~~ Like    	# -> ""

=head2 HasMethods[m...]

The object or the class has the methods.

	package HasMethodsExample {
		sub x1 {}
		sub x2 {}
	}
	
	"HasMethodsExample" ~~ HasMethods[qw/x1 x2/]    			# -> 1
	bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1 x2/] # -> 1
	bless({}, "HasMethodsExample") ~~ HasMethods[qw/x1/]    # -> 1
	"HasMethodsExample" ~~ HasMethods[qw/x3/]    				# -> ""
	"HasMethodsExample" ~~ HasMethods[qw/x1 x2 x3/]    		# -> ""
	"HasMethodsExample" ~~ HasMethods[qw/x1 x3/]    			# -> ""

=head2 Overload`[op...]

The object or the class is overloaded.

	package OverloadExample {
		use overload '""' => sub { "abc" };
	}
	
	"OverloadExample" ~~ Overload    # -> 1
	bless({}, "OverloadExample") ~~ Overload    # -> 1
	"A" ~~ Overload    				# -> ""
	bless({}, "A") ~~ Overload    	# -> ""

And it has the operators if arguments are specified.

	"OverloadExample" ~~ Overload['""']   # -> 1
	"OverloadExample" ~~ Overload['|']    # -> ""

=head2 InstanceOf[A...]

The class or the object inherits the list of classes.

	package Animal {}
	package Cat { our @ISA = qw/Animal/ }
	package Tiger { our @ISA = qw/Cat/ }
	
	
	"Tiger" ~~ InstanceOf['Animal', 'Cat']    # -> 1
	"Tiger" ~~ InstanceOf['Tiger']    		# -> ""
	"Tiger" ~~ InstanceOf['Cat', 'Dog']    	# -> ""

=head2 ConsumerOf[A...]

The class or the object has the roles.

=head2 StrLike

String or object with overloaded operator C<"">.

	"" ~~ StrLike    							# -> 1
	
	package StrLikeExample {
		use overload '""' => sub { "abc" };
	}
	
	bless({}, "StrLikeExample") ~~ StrLike    	# -> 1
	
	{} ~~ StrLike    							# -> ""

=head2 RegexpLike

The regular expression or the object with overloaded operator C<qr>.

	qr// ~~ RegexpLike    	# -> 1
	"" ~~ RegexpLike    	# -> ""
	
	package RegexpLikeExample {
		use overload 'qr' => sub { qr/abc/ };
	}
	
	"RegexpLikeExample" ~~ RegexpLike    # -> 1

=head2 CodeLike

The subroutines.

	sub {} ~~ CodeLike    	# -> 1
	\&CodeLike ~~ CodeLike  # -> 1
	{} ~~ CodeLike  		# -> ""

=head2 ArrayLike`[A]

The arrays or objects with overloaded operator C<@{}>.

	[] ~~ ArrayLike    	# -> 1
	{} ~~ ArrayLike    	# -> ""
	
	package ArrayLikeExample {
		use overload '@{}' => sub: lvalue { shift->{shift()} };
	}
	
	my $x = bless {}, 'ArrayLikeExample';
	$x->[1] = 12;
	$x  # --> bless {1 => 12}, 'ArrayLikeExample'
	
	$x ~~ ArrayLike    # -> 1

=head2 HashLike`[A]

The hashes or objects with overloaded operator C<%{}>.

	{} ~~ HashLike    	# -> 1
	[] ~~ HashLike    	# -> ""
	
	package HashLikeExample {
		use overload '%{}' => sub: lvalue { shift->[shift()] };
	}
	
	my $x = bless [], 'HashLikeExample';
	$x->{1} = 12;
	$x  # --> bless [undef, 12], 'HashLikeExample'
	
	$x ~~ HashLike    # -> 1
	

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>
