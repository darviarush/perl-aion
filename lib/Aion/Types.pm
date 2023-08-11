package Aion::Types;
# Типы-валидаторы для Aion

use common::sense;
use Aion::Type;
use Scalar::Util qw//;
use List::Util qw/all/;
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
            Optional
            Slurpy

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

    EmptyStrToUndef
    ArrayByComma
/;


my $SUB1 = sub {1};

# Создание типа
sub subtype(@) {
	my $save = my $name = shift;
	my %o = @_;
	
	my ($as, $init_where, $where, $awhere, $message) = @o{qw/as init_where where awhere message/};

	# TODO: subtype 'Str1[10]', as 'Str[1, A]'
	$as = Object([$as]) if defined $as and !ref $as;

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
			$where = $as->{test};
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
	die "coerce $type: Нет from" unless UNIVERSAL::isa($from, "Aion::Type");
	die "coerce $type: Нет via" unless ref $via eq "CODE";

	push @{$type->{coerce}}, [$from, $via];
	return;
}

sub from($) { (from => $_[0]) }
sub via(&) { (via => $_[0]) }

=pod
Any
	Item
		Bool
		Enum[e...]
		Maybe[a]
		Undef
		Defined
			Value
				Readonly
				Version
				Str
					Num
						PositiveNum
						Int
							PositiveInt
							Nat
					#ClassName
					#RoleName
			Ref
				ScalarRef`[a]
				ArrayRef`[a]
				HashRef`[a]
				CodeRef
				RegexpRef
				GlobRef
				FileHandle -> ref *STDIN{IO} = IO
				Object
				FormatRef -> ref *STDOUT{FORMAT}
				LValueRef -> ref \vec 42, 1, 2 || ref \substr "abc", 1, 2
			Like
				StringLike
				CodeLike
				RegexpLike -> Scalar::Util::reftype
				HashLike`[A]
				ArrayLike`[A]
				ScalarLike`[A]
				RefLike`[A]
=cut

BEGIN {

subtype "Any";
	subtype "Control", as &Any;
		subtype "Union[A, B...]", as &Control, 
			where { my $val = $_; any { $_->include($val) } ARGS };
		subtype "Intersection[A, B...]", as &Control, 
			where { my $val = $_; all { $_->include($val) } ARGS };
		subtype "Exclude[A, B...]", as &Control, 
			where { my $val = $_; !any { $_->include($val) } ARGS };
		subtype "Optional[A...]", as &Control,
			where {...};
		subtype "Slurpy[A...]", as &Control,
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
			init_where { ArrayRef([Object(['Aion::Type'])])->validate(scalar ARGS) }
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
			init_where { ArrayRef([Object(['Aion::Type'])])->validate(scalar ARGS) }
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
				subtype "GlobRef`[A]", as &Ref, 
					where { ref $_ eq "GLOB" }
					awhere { ref $_ eq "GLOB" && A->include($$_) };
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
					#subtype "Date", as Object(['Pleroma::Date']);

				subtype "Map[K, V]", as &HashRef,
					where {
						my ($K, $V) = ARGS;
						while(my ($k, $v) = each %$_) {
							return "" unless $K->include($k) && $V->include($v);
						}
						return 1;
					};

				subtype "Tuple[A...]", as &ArrayRef,
					init_where { ArrayRef([Object(['Aion::Type'])])->validate(scalar ARGS) }
					where {
						my $T = ARGS;
						return "" unless @$T == @$_;
						my $i = 0;
						for(@$_) { return "" unless $T->[$i++]->test }
						return 1;
					};
				subtype "CycleTuple[A...]", as &ArrayRef,
					init_where { ArrayRef([Object(['Aion::Type'])])->validate(scalar ARGS) }
					where {
						my $T = ARGS;
						return "" unless @$_ % @$T == 0;
						my $i = 0;
						for(@$_) {
							return "" unless $T->[$i++ % @$T]->test
						}
						return 1;
					};
				subtype "Dict[k => A, ...]", as &HashRef,
					init_where { CycleTuple([&Str => Object(['Aion::Type'])])->validate(scalar ARGS) }
					where {
						my $T = ARGS;
						return "" if @$T / 2 != keys(%$_);
						my $i = 0; my $k;
						for my $A (@$T) {
							$k = $A, next if $i++ % 2 == 0;
							return "" unless exists $_->{$k} && $A->include($_->{$k});
						}
						return 1;
					};
					

		
		# Array <- Slurpy[ArrayRef]
		# Hash <- Slurpy[HashRef]
		# MapOf[K, V...] <-  Slurpy[Map[K, V]]
		# TupleOf[K...] <-  Slurpy[Tuple[K...]]
		# CycleTupleOf[K...] <-  Slurpy[CycleTuple[K...]]
				# Slurpy
				# Optional[A...]
				
			subtype "Like", as (&Str | &Object);
				subtype "HasMethods[m...]", as &Like,
					where { my $x = $_; all { $x->can($_) } @{$_[1]} };
				subtype "Overload`[m...]", as &Like,
					where { !!overload::Overloaded($_) }
					awhere { my $x = $_; all { overload::Method($x, $_) } @{$_[1]} };

				subtype "InstanceOf[A...]", as &Like, where { my $x = $_; all { $x->isa($_) } ARGS };
				subtype "ConsumerOf[A...]", as &Like, where { my $x = $_; all { $x->DOES($_) } ARGS };
				#subtype "Self", as &Like, where { my $x = $_; all { $x->DOES($_) } @{$_[0]} };

			subtype "StrLike", as (&Str | Overload(['""']));
			subtype "RegexpLike", as (&RegexpRef | Overload(['qr']));
			subtype "CodeLike", as (&CodeRef | Overload(['&{}']));
			subtype "ArrayLike`[A]", as &Ref,
				where { Scalar::Util::reftype($_) eq "ARRAY" || overload::Method($_, '@{}') }
				awhere { &ArrayLike->test && do { my $A = A; all { $A->test } @$_ }};
			subtype "HashLike`[A]", as &Ref,
				where { Scalar::Util::reftype($_) eq "HASH" || overload::Method($_, "%{}") }
				awhere { &HashLike->test && do { my $A = A; all { $A->test } values %$_ }};

coerce "EmptyStrToUndef", from &Str, via { $_ eq ""? undef: $_ };
coerce "ArrayByComma", from &Str, via { [split /,/, $_] };

};

1;

__END__

=encoding utf-8

=head1 NAME

Aion::Types is library of validators. And it makes new validators

=head1 SYNOPSIS

	use Aion::Types;
	
	# Create validator SpeakOfKitty extends it from validator StrMatch.
	BEGIN {
	    subtype "SpeakOfKitty", as StrMatch[qr/\bkitty\b/i],
	        message { "Speak not of kitty!" };
	}
	
	"Kitty!" ~~ SpeakOfKitty # => 1

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
			Optional[A...]
			Slurpy[A...]
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

=head2 Optional[A...]

=head2 Slurpy[A...]

=head2 Array`[A]

=head2 ATuple[A...]

=head2 ACycleTuple[A...]

=head2 Hash`[A]

=head2 HMap[K, V]

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

	3 ~~ Enum[1,2,3]        # -> 1
	"a" ~~ Enum["a", "b"]   # -> 1
	4 ~~ Enum[1,2,3]        # -> ""

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

.

	 ~~ Tel    # -> 1
	 ~~ Tel    # -> ""

=head2 Url

.

	 ~~ Url    # -> 1
	 ~~ Url    # -> ""

=head2 Path

.

	 ~~ Path    # -> 1
	 ~~ Path    # -> ""

=head2 Html

.

	 ~~ Html    # -> 1
	 ~~ Html    # -> ""

=head2 StrDate

.

	 ~~ StrDate    # -> 1
	 ~~ StrDate    # -> ""

=head2 StrDateTime

.

	 ~~ StrDateTime    # -> 1
	 ~~ StrDateTime    # -> ""

=head2 StrMatch[qr/.../]

.

	 ~~ StrMatch[qr/.../]    # -> 1
	 ~~ StrMatch[qr/.../]    # -> ""

=head2 ClassName[A]

.

	 ~~ ClassName[A]    # -> 1
	 ~~ ClassName[A]    # -> ""

=head2 RoleName[A]

.

	 ~~ RoleName[A]    # -> 1
	 ~~ RoleName[A]    # -> ""

=head2 Numeric

.

	 ~~ Numeric    # -> 1
	 ~~ Numeric    # -> ""

=head2 Num

.

	 ~~ Num    # -> 1
	 ~~ Num    # -> ""

=head2 PositiveNum

.

	 ~~ PositiveNum    # -> 1
	 ~~ PositiveNum    # -> ""

=head2 Float

.

	 ~~ Float    # -> 1
	 ~~ Float    # -> ""

=head2 Range[from, to]

.

	 ~~ Range[from, to]    # -> 1
	 ~~ Range[from, to]    # -> ""

=head2 Int`[N]

.

	 ~~ Int`[N]    # -> 1
	 ~~ Int`[N]    # -> ""

=head2 PositiveInt`[N]

.

	 ~~ PositiveInt`[N]    # -> 1
	 ~~ PositiveInt`[N]    # -> ""

=head2 Nat`[N]

.

	 ~~ Nat`[N]    # -> 1
	 ~~ Nat`[N]    # -> ""

=head2 Ref

.

	 ~~ Ref    # -> 1
	 ~~ Ref    # -> ""

=head2 Tied`[A]

.

	 ~~ Tied`[A]    # -> 1
	 ~~ Tied`[A]    # -> ""

=head2 LValueRef

.

	 ~~ LValueRef    # -> 1
	 ~~ LValueRef    # -> ""

=head2 FormatRef

.

	 ~~ FormatRef    # -> 1
	 ~~ FormatRef    # -> ""

=head2 CodeRef

.

	 ~~ CodeRef    # -> 1
	 ~~ CodeRef    # -> ""

=head2 RegexpRef

.

	 ~~ RegexpRef    # -> 1
	 ~~ RegexpRef    # -> ""

=head2 ScalarRef`[A]

.

	 ~~ ScalarRef`[A]    # -> 1
	 ~~ ScalarRef`[A]    # -> ""

=head2 RefRef`[A]

.

	 ~~ RefRef`[A]    # -> 1
	 ~~ RefRef`[A]    # -> ""

=head2 GlobRef`[A]

.

	 ~~ GlobRef`[A]    # -> 1
	 ~~ GlobRef`[A]    # -> ""

=head2 ArrayRef`[A]

.

	 ~~ ArrayRef`[A]    # -> 1
	 ~~ ArrayRef`[A]    # -> ""

=head2 HashRef`[H]

.

	 ~~ HashRef`[H]    # -> 1
	 ~~ HashRef`[H]    # -> ""

=head2 Object`[O]

.

	 ~~ Object`[O]    # -> 1
	 ~~ Object`[O]    # -> ""

=head2 Map[K, V]

.

	 ~~ Map[K, V]    # -> 1
	 ~~ Map[K, V]    # -> ""

=head2 Tuple[A...]

.

	 ~~ Tuple[A...]    # -> 1
	 ~~ Tuple[A...]    # -> ""

=head2 CycleTuple[A...]

.

	 ~~ CycleTuple[A...]    # -> 1
	 ~~ CycleTuple[A...]    # -> ""

=head2 Dict[k => A, ...]

.

	 ~~ Dict[k => A, ...]    # -> 1
	 ~~ Dict[k => A, ...]    # -> ""

=head2 Like

.

	 ~~ Like    # -> 1
	 ~~ Like    # -> ""

=head2 HasMethods[m...]

.

	 ~~ HasMethods[m...]    # -> 1
	 ~~ HasMethods[m...]    # -> ""

=head2 Overload`[m...]

.

	 ~~ Overload`[m...]    # -> 1
	 ~~ Overload`[m...]    # -> ""

=head2 InstanceOf[A...]

.

	 ~~ InstanceOf[A...]    # -> 1
	 ~~ InstanceOf[A...]    # -> ""

=head2 ConsumerOf[A...]

.

	 ~~ ConsumerOf[A...]    # -> 1
	 ~~ ConsumerOf[A...]    # -> ""

=head2 StrLike

.

	 ~~ StrLike    # -> 1
	 ~~ StrLike    # -> ""

=head2 RegexpLike

.

	 ~~ RegexpLike    # -> 1
	 ~~ RegexpLike    # -> ""

=head2 CodeLike

.

	 ~~ CodeLike    # -> 1
	 ~~ CodeLike    # -> ""

=head2 ArrayLike`[A]

.

	 ~~ ArrayLike`[A]    # -> 1
	 ~~ ArrayLike`[A]    # -> ""

=head2 HashLike`[A]

.

	 ~~ HashLike`[A]    # -> 1
	 ~~ HashLike`[A]    # -> ""

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>
