package Aion;
use 5.008001;
use common::sense;

our $VERSION = "0.01";

use Scalar::Util qw/blessed weaken/;
use Aion::Types qw//;

# Когда осуществлять проверки:
#   ro - только при выдаче
#   wo - только при установке
#   rw - при выдаче и уcтановке
#   no - никогда не проверять
use config ISA => 'rw';

sub export($@);

# Классы в которых подключён Aion с метаинформацией
our %META;

# вызывается из другого пакета, для импорта данного
sub import {
	my ($cls, $attr) = @_;
	my ($pkg, $path) = caller;

	*{"${pkg}::isa"} = \&isa if \&isa != $pkg->can('isa');

    if($attr ne '-role') {  # Класс
		export $pkg, qw/new extends/;
    } else {    # Роль
		export $pkg, qw/requires/;
    }

	export $pkg, qw/with upgrade has aspect does clear/;

    # Метаинформация
	$META{$pkg} = {
		feature => {},
		aspect => {
			is => \&is_aspect,
			isa => \&isa_aspect,
			coerce => \&coerce_aspect,
			default => \&default_aspect,
			trigger => \&trigger_aspect,
		}
	};

    #Aion::Types->import($pkg);
    eval "package $pkg { use Aion::Types; }";
    die if $@;
}

# Экспортирует функции в пакет, если их там ещё нет
sub export($@) {
	my $pkg = shift;
	for my $sub (@_) {
		my $can = $pkg->can($sub);
		die "$pkg can $sub!" if $can && $can != \&$sub;
		*{"${pkg}::$sub"} = \&$sub unless $can;
	}
}

# Экспортирует функции в пакет, если их там ещё нет
sub is_aion($) {
	my $pkg = shift;
	die "$pkg is'nt class of Aion!" if !exists $META{$pkg};
}

#@category Aspects

sub _weaken_init {
	my ($self, $feature) = @_;
	weaken $self->{$feature->{name}};
}

# ro, rw, + и -
sub is_aspect {
    my ($cls, $name, $is, $construct, $feature) = @_;
    die "Use is => '(ro|rw|wo|no)[+-]?[*]?'" if $is !~ /^(ro|rw|wo|no)[+-]?[*]?\z/;

    $construct->{get} = "die 'has: $name is $is (not get)'" if $is =~ /^(wo|no)/;

	if($is =~ /^(ro|no)/) {
    	$construct->{set} = "die 'has: $name is $is (not set)'";
	}
	elsif($is =~ /\*\z/) {
		$construct->{ret} = "; Scalar::Util::weaken(\$self->{$name})$construct->{ret}";
	}

    $feature->{required} = 1 if $is =~ /\+/;
    $feature->{excessive} = 1 if $is =~ /-/;
    push @{$feature->{init}}, \&_weaken_init if $is =~ /\*\z/;
}

# isa => Type
sub isa_aspect {
    my ($cls, $name, $isa, $construct, $feature) = @_;
    die "has: $name - isa maybe Aion::Type"
        if !UNIVERSAL::isa($isa, 'Aion::Type');

    $feature->{isa} = $isa;

    $construct->{get} = "\$Aion::META{'$cls'}{feature}{$name}{isa}->validate(do{$construct->{get}}, 'Get feature `$name`')" if ISA =~ /ro|rw/;

    $construct->{set} = "\$Aion::META{'$cls'}{feature}{$name}{isa}->validate(\$val, 'Set feature `$name`'); $construct->{set}" if ISA =~ /wo|rw/;
}

# coerce => 1
sub coerce_aspect {
    my ($cls, $name, $coerce, $construct, $feature) = @_;

	return unless $coerce;

	die "coerce: isa not present!" unless $feature->{isa};

    $construct->{coerce} = "\$val = \$Aion::META{'$cls'}{feature}{$name}{isa}->coerce(\$val); ";
    $construct->{set} = "%(coerce)s$construct->{set}"
}

# default => value
sub default_aspect {
    my ($cls, $name, $default, $construct, $feature) = @_;

    if(ref $default eq "CODE") {
        $feature->{lazy} = 1;
        *{"${cls}::${name}__DEFAULT"} = $default;
        $construct->{get} = "\$self->{$name} = \$self->${name}__DEFAULT if !exists \$self->{$name}; $construct->{get}";
    } else {
        $feature->{opt}{isa}->validate($default, $name) if $feature->{opt}{isa};
        $feature->{default} = $default;
    }
}

sub _trigger_init {
	my ($self, $feature) = @_;
	$feature->{trigger}->($self);
}

# trigger => $sub
sub trigger_aspect {
	my ($cls, $name, $trigger, $construct, $feature) = @_;

	$feature->{trigger} = *{"${cls}::${name}__TRIGGER"} = $trigger;
	$construct->{set} = "my \$old = \$self->{$name}; $construct->{set}; \$self->${name}__TRIGGER(\$old)";

	push @{$feature->{init}}, \&_trigger_init;
}

# Расширяет класс или роль
sub inherits($$@) {
    my $pkg = shift; my $with = shift;

	is_aion $pkg;

    my $FEATURE = $Aion::META{$pkg}{feature};
    my $ASPECT = $Aion::META{$pkg}{aspect};

    # Добавляем наследуемые свойства и атрибуты
	for my $module (@_) {
        eval "require $module" or die unless $module->can('with') || $module->can('new');

		if(my $meta = $Aion::META{$module}) {
			%$FEATURE = (%$FEATURE, %{$meta->{feature}}) ;
			%$ASPECT = (%$ASPECT, %{$meta->{aspect}});
		}
	}

    my $import_name = $with? 'import_with': 'import_extends';
    for my $module (@_) {
        my $import = $module->can($import_name);
        $import->($module, $pkg) if $import;

		if($with && exists $Aion::META{$module} && (my $requires = $Aion::META{$module}{requires})) {
			my @not_requires = grep { !$pkg->can($_) } @$requires;

			do { local $, = ", "; die "@not_requires requires!" } if @not_requires;
		}
    }

    return;
}

# Наследование классов
sub extends(@) {
	my $pkg = caller;

	is_aion $pkg;

	push @{"${pkg}::ISA"}, @_;
	push @{$Aion::META{$pkg}{extends}}, @_;

    unshift @_, $pkg, 0;
    goto &inherits;
}

# Расширение ролями
sub with(@) {
	my $pkg = caller;

	is_aion $pkg;

	push @{"${pkg}::ISA"}, @_;
	push @{$Aion::META{$pkg}{with}}, @_;

    unshift @_, $pkg, 1;
    goto &inherits;
}

# Требуются подпрограммы
sub requires(@) {
    my $pkg = caller;

	is_aion $pkg;

    push @{$Aion::META{$pkg}{requires}}, @_;
    return;
}



# Требуются подпрограммы
sub aspect($$) {
	my ($name, $sub) = @_;
    my $pkg = caller;

	is_aion $pkg;

	my $ASPECT = $Aion::META{$pkg}{aspect};
	die "Aspect `$name` exists!" if exists $ASPECT->{$name};
    $ASPECT->{$name} = $sub;
    return;
}

# Определяет - расширен ли класс
sub isa {
    my ($self, $class) = @_;

    my $pkg = ref $self || $self;

	return 1 if $class eq $pkg;

	my $meta = $Aion::META{$pkg};
    my $extends = $meta->{extends} // return "";

    return 1 if $class ~~ $extends;
    for my $extender (@$extends) {
        return 1 if $extender->isa($class);
    }

    return "";
}

# Определяет - подключена ли роль
sub does {
    my ($self, $role) = @_;

    my $pkg = ref $self || $self;
	my $meta = $Aion::META{$pkg};
	my $does = $meta->{with} // return "";

    return 1 if $role ~~ $does;
    for my $doeser (@$does) {
        return 1 if $doeser->can("does") && $doeser->does($role);
    }

    return "";
}

# Очищает переменную в объекте, возвращает себя
sub clear {
    my $self = shift;
    delete @$self{@_};
    $self
}

# Создаёт свойство
sub has(@) {
	my $property = shift;

    return exists $property->{$_[0]} if blessed $property;

	my $pkg = caller;
	is_aion $pkg;

    my %opt = @_;
	my $meta = $Aion::META{$pkg};

	# атрибуты
	for my $name (ref $property? @$property: $property) {

		die "has: the method $name is already in the package $pkg"
            if $pkg->can($name) && !exists $meta->{feature}{$name};

        my %construct = (
            pkg => $pkg,
            name => $name,
			attr => '',
			eval => 'package %(pkg)s {
	%(sub)s
}',
            sub => 'sub %(name)s%(attr)s {
		if(@_>1) {
			my ($self, $val) = @_;
			%(set)s%(ret)s
		} else {
			my ($self) = @_;
			%(get)s
		}
	}',
            get => '$self->{%(name)s}',
            set => '$self->{%(name)s} = $val',
			ret => '; $self',
        );

        my $feature = {
            has => [@_],
            opt => \%opt,
            name => $name,
            construct => \%construct,
        };

        my $ASPECT = $meta->{aspect};
        for(my $i=0; $i<@_; $i+=2) {
            my ($aspect, $value) = @_[$i, $i+1];
            my $aspect_sub = $ASPECT->{$aspect};
            die "has: not exists aspect `$aspect`!" if !$aspect_sub;
            $aspect_sub->($pkg, $name, $value, \%construct, $feature);
        }

        my $sub = _resolv($construct{eval}, \%construct);
		eval $sub;
		die if $@;

        $feature->{sub} = $sub;
		$meta->{feature}{$name} = $feature;
	}
	return;
}

sub _resolv {
    my ($s, $construct) = @_;
    $s =~ s{%\((\w*)\)s}{
        die "has: not construct `$1`\!" unless exists $construct->{$1};
        _resolv($construct->{$1}, $construct);
    }ge;
    $s
}

# конструктор
sub new {
	my ($self, @errors) = create_from_params(@_);

	die join "", "has:\n\n", map "* $_\n", @errors if @errors;

	$self
}

# Устанавливает свойства и выдаёт объект и ошибки
sub create_from_params {
	my ($cls, %value) = @_;

	$cls = ref $cls || $cls;
	is_aion $cls;

	my $self = bless {}, $cls;

	my @init;
	my @required;
	my @errors;
    my $FEATURE = $Aion::META{$cls}{feature};

	while(my ($name, $feature) = each %$FEATURE) {

		if(exists $value{$name}) {
			my $val = delete $value{$name};

			if(!$feature->{excessive}) {
				$val = $feature->{coerce}->coerce($val) if $feature->{coerce};

				push @errors, $feature->{isa}->detail($val, "Feature $name")
                    if ISA =~ /w/ && $feature->{isa} && !$feature->{isa}->include($val);
				$self->{$name} = $val;
				push @init, $feature if $feature->{init};
			}
			else {
				push @errors, "Feature $name cannot set in new!";
			}
		} elsif($feature->{required}) {
            push @required, $name;
        } elsif(exists $feature->{default}) {
			$self->{$name} = $feature->{default};
			push @init, $feature if $feature->{init};
		}

	}

	for my $feature (@init) {
		for my $init (@{$feature->{init}}) {
			$init->($self, $feature);
		}
	}

	do {local $" = ", "; unshift @errors, "Features @required is required!"} if @required > 1;
	unshift @errors, "Feature @required is required!" if @required == 1;
	
	my @fakekeys = sort keys %value;
	unshift @errors, "@fakekeys is not feature!" if @fakekeys == 1;
	do {local $" = ", "; unshift @errors, "@fakekeys is not features!"} if @fakekeys > 1;

	return $self, @errors;
}

1;

__END__

=encoding utf-8

=head1 NAME

B<Aion> — A postmodern object system for Perl 5, as C<Moose> and C<Moo>, but with improvements.

=head1 VERSION

0.01

=head1 SYNOPSIS

	package Calc {
	
	    use Aion;
	
	    has a => (is => 'ro+', isa => Num);
	    has b => (is => 'ro+', isa => Num);
	    has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');
	
	    sub result {
	        my ($self) = @_;
	        eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
	    }
	
	}
	
	Calc->new(a => 1.1, b => 2)->result   # => 3.1

=head1 DESCRIPTION

Aion — OOP framework for create classes with B<features>, has B<aspects>, B<roles> and so on.

Properties declared via C<has> are called B<features>.

And C<is>, C<isa>, C<default> and so on in C<has> are called B<aspects>.

In addition to standard aspects, roles can add their own aspects using subroutine C<aspect>.

=head1 SUBROUTINES IN CLASSES AND ROLES

C<use Aion> include in module types from C<Aion::Types> and next subroutines:

=head2 has ($name, %aspects)

Make method for get/set feature (property) of the class.

File lib/Animal.pm:

	package Animal;
	use Aion;
	
	has type => (is => 'ro+', isa => Str);
	has name => (is => 'rw-', isa => Str, default => 'murka');
	
	1;



	use lib "lib";
	use Animal;
	
	my $cat = Animal->new(type => 'cat');
	
	$cat->type   # => cat
	$cat->name   # => murka
	
	$cat->name("murzik");
	$cat->name   # => murzik

=head2 with

Add to module roles. It call on each the role method C<import_with>.

File lib/Role/Keys/Stringify.pm:

	package Role::Keys::Stringify;
	
	use Aion -role;
	
	sub keysify {
	    my ($self) = @_;
	    join ", ", sort keys %$self;
	}
	
	1;

File lib/Role/Values/Stringify.pm:

	package Role::Values::Stringify;
	
	use Aion -role;
	
	sub valsify {
	    my ($self) = @_;
	    join ", ", map $self->{$_}, sort keys %$self;
	}
	
	1;

File lib/Class/All/Stringify.pm:

	package Class::All::Stringify;
	
	use Aion;
	
	with qw/Role::Keys::Stringify Role::Values::Stringify/;
	
	has [qw/key1 key2/] => (is => 'rw', isa => Str);
	
	1;



	use lib "lib";
	use Class::All::Stringify;
	
	my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");
	
	$s->keysify     # => key1, key2
	$s->valsify     # => a, b

=head2 isa ($package)

Check C<$package> is the class what extended this class.

	package Ex::X { use Aion; }
	package Ex::A { use Aion; extends qw/Ex::X/; }
	package Ex::B { use Aion; }
	package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }
	
	Ex::C->isa("Ex::A") # -> 1
	Ex::C->isa("Ex::B") # -> 1
	Ex::C->isa("Ex::X") # -> 1
	Ex::C->isa("Ex::X1") # -> ""
	Ex::A->isa("Ex::X") # -> 1
	Ex::A->isa("Ex::A") # -> 1
	Ex::X->isa("Ex::X") # -> 1

=head2 does ($package)

Check C<$package> is the role what extended this class.

	package Role::X { use Aion -role; }
	package Role::A { use Aion; with qw/Role::X/; }
	package Role::B { use Aion; }
	package Ex::Z { use Aion; with qw/Role::A Role::B/ }
	
	Ex::Z->does("Role::A") # -> 1
	Ex::Z->does("Role::B") # -> 1
	Ex::Z->does("Role::X") # -> 1
	Role::A->does("Role::X") # -> 1
	Role::A->does("Role::X1") # -> ""
	Ex::Z->does("Ex::Z") # -> ""

=head2 aspect ($aspect => sub { ... })

It add aspect to C<has> in this class or role, and to the classes, who use this role, if it role.

	package Example::Earth {
	    use Aion;
	
	    aspect lvalue => sub {
	        my ($cls, $name, $value, $construct, $feature) = @_;
	
	        $construct->{attr} .= ":lvalue";
	    };
	
	    has moon => (is => "rw", lvalue => 1);
	}
	
	my $earth = Example::Earth->new;
	
	$earth->moon = "Mars";
	
	$earth->moon # => Mars

Aspect is called every time it is specified in C<has>.

Aspect handler has parameters:

=over

=item * C<$cls> — the package with the C<has>.

=item * C<$name> — the feature name.

=item * C<$value> — the aspect value.

=item * C<$construct> — the hash with code fragments for join to the feature method.

=item * C<$feature> — the hash present feature.

=back

	package Example::Mars {
	    use Aion;
	
	    aspect lvalue => sub {
	        my ($cls, $name, $value, $construct, $feature) = @_;
	
	        $construct->{attr} .= ":lvalue";
	
	        $cls # => Example::Mars
	        $name # => moon
	        $value # -> 1
	        [sort keys %$construct] # --> [qw/attr eval get name pkg ret set sub/]
	        [sort keys %$feature] # --> [qw/construct has name opt/]
	
	        my $_construct = {
	            pkg => $cls,
	            name => $name,
				attr => ':lvalue',
				eval => 'package %(pkg)s {
		%(sub)s
	}',
	            sub => 'sub %(name)s%(attr)s {
			if(@_>1) {
				my ($self, $val) = @_;
				%(set)s%(ret)s
			} else {
				my ($self) = @_;
				%(get)s
			}
		}',
	            get => '$self->{%(name)s}',
	            set => '$self->{%(name)s} = $val',
	            ret => '; $self',
	        };
	
	        $construct # --> $_construct
	
	        my $_feature = {
	            has => [is => "rw", lvalue => 1],
	            opt => {
	                is => "rw",
	                lvalue => 1,
	            },
	            name => $name,
	            construct => $_construct,
	        };
	
	        $feature # --> $_feature
	    };
	
	    has moon => (is => "rw", lvalue => 1);
	}

=head1 SUBROUTINES IN CLASSES

=head2 extends (@superclasses)

Extends package other package. It call on each the package method C<import_extends> if it exists.

	package World { use Aion;
	
	    our $extended_by_this = 0;
	
	    sub import_extends {
	        my ($class, $extends) = @_;
	        $extended_by_this ++;
	
	        $class      # => World
	        $extends    # => Hello
	    }
	}
	
	package Hello { use Aion;
	    extends qw/World/;
	
	    $World::extended_by_this # -> 1
	}
	
	Hello->isa("World")     # -> 1

=head2 new (%param)

Constructor. 

=over

=item * Set C<%param> to features.

=item * Check if param not mapped to feature.

=item * Set default values.

=back

	package NewExample { use Aion;
	    has x => (is => 'ro', isa => Num);
	    has y => (is => 'ro+', isa => Num);
	    has z => (is => 'ro-', isa => Num);
	}
	
	eval { NewExample->new(f => 5) }; $@            # ~> f is not feature!
	eval { NewExample->new(n => 5, r => 6) }; $@    # ~> n, r is not features!
	eval { NewExample->new }; $@                    # ~> Feature y is required!
	eval { NewExample->new(z => 10) }; $@           # ~> Feature z cannot set in new!
	
	my $ex = NewExample->new(y => 8);
	
	eval { $ex->x }; $@  # ~> Get feature `x` must have the type Num. The it is undef
	
	$ex = NewExample->new(x => 10.1, y => 8);
	
	$ex->x # -> 10.1

=head1 SUBROUTINES IN ROLES

=head2 requires (@subroutine_names)

Check who in classes who use the role present the subroutines.

	package Role::Alpha { use Aion -role;
	
	    sub in {
	        my ($self, $s) = @_;
	        $s =~ /[${\ $self->abc }]/
	    }
	
	    requires qw/abc/;
	}
	
	eval { package Omega1 { use Aion; with Role::Alpha; } }; $@ # ~> abc requires!
	
	package Omega { use Aion;
	    with Role::Alpha;
	
	    sub abc { "abc" }
	}
	
	Omega->new->in("a")  # -> 1

=head1 METHODS

=head2 has ($feature)

It check what property is set.

	package ExHas { use Aion;
	    has x => (is => 'rw');
	}
	
	my $ex = ExHas->new;
	
	$ex->has("x")   # -> ""
	
	$ex->x(10);
	
	$ex->has("x")   # -> 1

=head2 clear (@features)

Cleared the features.

	package ExClear { use Aion;
	    has x => (is => 'rw');
	    has y => (is => 'rw');
	}
	
	my $c = ExClear->new(x => 10, y => 12);
	
	$c->has("x")   # -> 1
	$c->has("y")   # -> 1
	
	$c->clear(qw/x y/);
	
	$c->has("x")   # -> ""
	$c->has("y")   # -> ""

=head1 METHODS IN CLASSES

C<use Aion> include in module next methods:

=head2 new (%parameters)

The constructor.

=head1 ASPECTS

C<use Aion> include in module next aspects for use in C<has>:

=head2 is => $permissions

=over

=item * C<ro> — make getter only.

=item * C<wo> — make setter only.

=item * C<rw> — make getter and setter.

=back

Default is C<rw>.

Additional permissions:

=over

=item * C<+> — the feature is required. It is not used with C<->.

=item * C<-> — the feature cannot be set in the constructor. It is not used with C<+>.

=item * C<*> — the value is reference and it maked weaken can be set.

=back

	package ExIs { use Aion;
	    has rw => (is => 'rw');
	    has ro => (is => 'ro+');
	    has wo => (is => 'wo-');
	}
	
	eval { ExIs->new }; $@ # ~> \* Feature ro is required!
	eval { ExIs->new(ro => 10, wo => -10) }; $@ # ~> \* Feature wo cannot set in new!
	ExIs->new(ro => 10);
	ExIs->new(ro => 10, rw => 20);
	
	ExIs->new(ro => 10)->ro  # -> 10
	
	ExIs->new(ro => 10)->wo(30)->has("wo")  # -> 1
	eval { ExIs->new(ro => 10)->wo }; $@ # ~> has: wo is wo- \(not get\)
	ExIs->new(ro => 10)->rw(30)->rw  # -> 30

Feature with C<*> don't hold value:

	package Node { use Aion;
	    has parent => (is => "rw*", isa => Maybe[Object["Node"]]);
	}
	
	my $root = Node->new;
	my $node = Node->new(parent => $root);
	
	$node->parent->parent   # -> undef
	undef $root;
	$node->parent   # -> undef
	
	# And by setter:
	$node->parent($root = Node->new);
	
	$node->parent->parent   # -> undef
	undef $root;
	$node->parent   # -> undef

=head2 isa => $type

Set feature type. It validate feature value 

=head2 default => $value

Default value set in constructor, if feature falue not present.

	package ExDefault { use Aion;
	    has x => (is => 'ro', default => 10);
	}
	
	ExDefault->new->x  # -> 10
	ExDefault->new(x => 20)->x  # -> 20

If C<$value> is subroutine, then the subroutine is considered a constructor for feature value. This subroutine lazy called where the value get.

	my $count = 10;
	
	package ExLazy { use Aion;
	    has x => (default => sub {
	        my ($self) = @_;
	        ++$count
	    });
	}
	
	my $ex = ExLazy->new;
	$count   # -> 10
	$ex->x   # -> 11
	$count   # -> 11
	$ex->x   # -> 11
	$count   # -> 11

=head2 trigger => $sub

C<$sub> called after the value of the feature is set (in C<new> or in setter).

	package ExTrigger { use Aion;
	    has x => (trigger => sub {
	        my ($self, $old_value) = @_;
	        $self->y($old_value + $self->x);
	    });
	
	    has y => ();
	}
	
	my $ex = ExTrigger->new(x => 10);
	$ex->y      # -> 10
	$ex->x(20);
	$ex->y      # -> 30

=head1 ATTRIBUTES

Aion add universal attributes.

=head2 Isa (@signature)

Attribute C<Isa> check the signature the function where it called.

B<WARNING>: use atribute C<Isa> slows down the program.

B<TIP>: use aspect C<isa> on features is more than enough to check the correctness of the object data.

	package Anim { use Aion;
	
	    sub is_cat : Isa(Object => Str => Bool) {
	        my ($self, $anim) = @_;
	        $anim =~ /(cat)/
	    }
	}
	
	my $anim = Anim->new;
	
	$anim->is_cat('cat')    # -> 1
	$anim->is_cat('dog')    # -> ""
	
	
	eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].
	eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].

If use name of type in C<@signature>, then call subroutine with this name from current package.

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>
