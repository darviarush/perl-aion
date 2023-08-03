package Aion::Types;
# Типы-валидаторы для Aion

use common::sense;
use Aion::Type;
use Scalar::Util qw//;
use List::Util qw/all/;
use Exporter qw/import/;

our @EXPORT_OK = qw/
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
# coerce Name from OtherName1 via {...} from OtherName2 via {...} ...
sub coerce(@) {
	my $save = my $name = shift;
	my %o = @_;

	my ($from, $via) = @o{qw/from via/};
	
	die "coerce $save: Нет from" if !$from;
	die "coerce $save: Нет via" if !$via;

	my $coerce = Aion::Type->new(name => $name, coerce => $via, from => $from);
	$coerce->make(scalar caller)
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
					subtype "Html", as &Str, where { /^\s*<(!|html)/ };
					subtype "StrDate", as &Str, where { /^\d{4}-\d{2}-\d{2}\z/ };
					subtype "StrDateTime", as &Str, where { /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\z/ };
					subtype "StrMatch[qr/.../]", as &Str, where { $_ =~ A };
					
					subtype "ClassName[A]", as &Str, where { A->can('new') };
					subtype "RoleName[A]", as &Str, where { !A->can('new') };
					
					subtype "Numeric", as &Str, where { Scalar::Util::looks_like_number($_) };
						subtype "Num", as &Numeric, where { /\d\z/ };
							subtype "PositiveNum", as &Num, where { $_ >= 0 };
							subtype "Float", as &Num, where { -3.402823466E+38 <= $_ <= 3.402823466E+38 };
							subtype "Range[from, to]", as &Num, where { A <= $_ && $_ <= B };
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