package Aion;
use 5.008001;
use common::sense;

our $VERSION = "0.01";

use Scalar::Util qw/blessed/;
use Aion::Types qw//;

# Когда осуществлять проверки:
#   ro - только при выдаче
#   wo - только при установке
#   rw - при выдаче и уcтановке
#   no - никогда не проверять
use config ISA => 'rw';

sub export($@);

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

    # Свойства объекта
	constant->import("${pkg}::META" => {
		feature => {},
		aspect => {
			is => \&is_aspect,
			isa => \&isa_aspect,
			coerce => \&coerce_aspect,
			default => \&default_aspect,
		}
	});

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

#@category Aspects

# ro, rw, + и -
sub is_aspect {
    my ($cls, $name, $is, $construct, $feature) = @_;
    die "Use is => '(ro|rw|wo|no)[+-]?'" if $is !~ /^(ro|rw|wo|no)[+-]?\z/;

    $construct->{get} = "die 'has: $name is $is (not get)'" if $is =~ /^(wo|no)/;
    $construct->{set} = "die 'has: $name is $is (not set)'" if $is =~ /^(ro|no)/;

    $feature->{required} = 1 if $is =~ /\+$/;
    $feature->{not_in_new} = 1 if $is =~ /-$/;
}

# isa => Type
sub isa_aspect {
    my ($cls, $name, $isa, $construct, $feature) = @_;
    die "has: $name - isa maybe Aion::Type"
        if !UNIVERSAL::isa($isa, 'Aion::Type');

    $feature->{isa} = $isa;

    $construct->{get} = "\$self->META->{feature}{$name}{isa}->validate(do{$construct->{get}}, 'Get feature `$name`')" if ISA =~ /ro|rw/;

    $construct->{set} = "\$self->META->{feature}{$name}{isa}->validate(\$val, 'Set feature `$name`'); $construct->{set}" if ISA =~ /wo|rw/;
}

# coerce => 1
sub coerce_aspect {
    my ($cls, $name, $type, $construct, $feature) = @_;

	die "coerce: isa not present!" unless $feature->{isa};

    $construct->{coerce} = "\$val = \$self->META->{feature}{$name}{isa}->coerce(\$val); ";
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

# Расширяет класс или роль
sub inherits($$@) {
    my $pkg = shift; my $with = shift;

    my $FEATURE = $pkg->META->{feature};
    my $ASPECT = $pkg->META->{aspect};

    # Добавляем наследуемые свойства и атрибуты
	for my $module (@_) {
        eval "require $module" or die unless $module->can('with') || $module->can('new');

		if($module->can("META")) {
			%$FEATURE = (%$FEATURE, %{$module->META->{feature}}) ;
			%$ASPECT = (%$ASPECT, %{$module->META->{aspect}});
		}
	}

    my $import_name = $with? 'import_with': 'import_extends';
    for my $module (@_) {
        my $import = $module->can($import_name);
        $import->($module, $pkg) if $import;

		if($with && $module->can("META") && $module->META->{requires}) {
			for my $require (@{$module->META->{requires}}) {
				die "Requires `$require`!" if !$pkg->can($require);
			}
		}
    }

    return;
}

# Наследование классов
sub extends(@) {
	my $pkg = caller;

	push @{"${pkg}::ISA"}, @_;
	push @{$pkg->META->{extends}}, @_;

    unshift @_, $pkg, 0;
    goto &inherits;
}

# Расширение ролями
sub with(@) {
	my $pkg = caller;

	push @{"${pkg}::ISA"}, @_;
	push @{$pkg->META->{with}}, @_;

    unshift @_, $pkg, 1;
    goto &inherits;
}

# Требуются подпрограммы
sub requires(@) {
    my $pkg = caller;
    push @{$pkg->META->{requires}}, @_;
    return;
}

# Требуются подпрограммы
sub aspect($$) {
	my ($name, $sub) = @_;
    my $pkg = caller;
	my $ASPECT = $pkg->META->{aspect};
	die "Aspect `$name` exists!" if exists $ASPECT->{$name};
    $ASPECT->{$name} = $sub;
    return;
}

# Определяет - расширен ли класс
sub isa {
    my ($self, $class) = @_;

    my $pkg = ref $self || $self;

	return 1 if $class eq $pkg;

    my $extends = $pkg->META->{extends} // return "";

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
	my $does = $pkg->META->{with} // return "";

    return 1 if $role ~~ $does;
    for my $doeser (@$does) {
        return 1 if $doeser->can("does") && $doeser->does($role);
    }

    return "";
}

# Очищает переменную в объекте, возвращает себя
sub clear {
    my ($self, $feature) = @_;
    delete $self->{$feature};
    $self
}

# создаёт свойство
sub has(@) {
	my $property = shift;

    return exists $property->{$_[0]} if blessed $property;

	my $pkg = caller;
    my %opt = @_;
	my $meta = $pkg->META;

	# атрибуты
	for my $name (ref $property? @$property: $property) {

		die "has: the method $name is already in the package $pkg"
            if $pkg->can($name) && !exists $pkg->ASPECT->{$name};

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
			%(set)s
		} else {
			my ($self) = @_;
			%(get)s
		}
	}',
            get => '$self->{%(name)s}',
            set => '$self->{%(name)s} = $val; $self',
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
	my $self = bless {}, $cls;

	my @required;
	my @errors;
    my $FEATURE = $cls->META->{feature};

	while(my ($name, $feature) = each %$FEATURE) {

		if(exists $value{$name}) {
			my $val = delete $value{$name};

			if(!$feature->{not_in_new}) {
				$val = $feature->{coerce}->coerce($val) if $feature->{coerce};

				push @errors, $feature->{isa}->detail($val, "Feature $name")
                    if ISA =~ /w/ && $feature->{isa} && !$feature->{isa}->include($val);
				$self->{$name} = $val;
			}
			else {
				push @errors, "Feature $name not set in new!";
			}
		} elsif($feature->{required}) {
            push @required, $name;
        } else {
			$self->{$name} = $feature->{default} if !$feature->{lazy};
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

=head2 has ($name, @aspects)

Make method for get/set feature (property) of the class.

File lib/Animal.pm:

	package Animal;
	use Aion;
	
	has type => (is => 'ro+', isa => Str);
	has name => (is => 'rw-', isa => Str);
	
	1;



	use lib "lib";
	use Animal;
	
	eval { Animal->new }; $@    # ~> Feature type is required!
	eval { Animal->new(name => 'murka') }; $@    # ~> Feature name not set in new!
	
	my $cat = Animal->new(type => 'cat');
	$cat->type   # => cat
	
	eval { $cat->name }; $@   # ~> Get feature `name` must have the type Str. The it is undef
	
	$cat->name("murzik");
	$cat->name  # => murzik

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
	        [sort keys %$construct] # --> [qw/attr eval get name pkg set sub/]
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
				%(set)s
			} else {
				my ($self) = @_;
				%(get)s
			}
		}',
	            get => '$self->{%(name)s}',
	            set => '$self->{%(name)s} = $val; $self',
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

Extends package other package. It call on each the package method C<import_with> if it exists.

=head2 new (%params)

Constructor.

=head1 SUBROUTINES IN ROLES

=head2 requires (@subroutine_names)

It add aspect to the classes, who use this role.

=head1 METHODS

=head2 has ($feature)

It check what property is set.

=head2 clear ($feature)

It check what property is set.

=head1 METHODS IN CLASSES

C<use Aion> include in module next methods:

=head2 new (%parameters)

The constructor.

=head1 ATTRIBUTES

Aion add universal attributes.

=head2 Isa (@signature)

Attribute C<Isa> check the signature the function where it called.

B<WARNING>: use atribute C<Isa> slows down the program.

B<TIP>: use aspect C<isa> on features is more than enough to check the correctness of the object data.

	package Anim {
	    use Aion;
	
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
