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

# вызывается из другого пакета, для импорта данного
sub import {
	my ($cls, $attr) = @_;
	my ($pkg, $path) = caller;

    if($attr ne '-role') {  # Класс
	    *{"${pkg}::new"} = \&new;
        *{"${pkg}::extends"} = \&extends;
    } else {    # Роль
        *{"${pkg}::requires"} = \&requires;
    }

	*{"${pkg}::with"} = \&with;
	*{"${pkg}::upgrade"} = \&upgrade;
	*{"${pkg}::has"} = \&has;
	*{"${pkg}::aspect"} = \&aspect;
	*{"${pkg}::does"} = \&does;
	*{"${pkg}::clear"} = \&clear;

    # Свойства объекта
	constant->import("${pkg}::FEATURE" => {});

    # Атрибуты для has
	constant->import("${pkg}::ASPECT" => {
        is => \&_is,
        isa => \&_isa,
        coerce => \&_coerce,
        default => \&_default,
    });

    #Aion::Types->import($pkg);
    eval "package $pkg { use Aion::Types; }";
    die if $@;
}

#@category Aspects

# ro, rw, + и -
sub _is {
    my ($cls, $name, $is, $construct, $feature) = @_;
    die "Use is => '(ro|rw|wo|no)[+-]?'" if $is !~ /^(ro|rw|wo|no)[+-]?\z/;

    $construct->{get} = "die 'has: $name is $is (not get)'" if $is =~ /^(wo|no)/;
    $construct->{set} = "die 'has: $name is $is (not set)'" if $is =~ /^(ro|no)/;

    $feature->{required} = 1 if $is =~ /\+$/;
    $feature->{not_in_new} = 1 if $is =~ /-$/;
}

# isa => Type
sub _isa {
    my ($cls, $name, $isa, $construct, $feature) = @_;
    die "has: $name - isa maybe Aion::Type"
        if !UNIVERSAL::isa($isa, 'Aion::Type');

    $feature->{isa} = $isa;

    $construct->{get} = "\$self->FEATURE->{$name}{isa}->validate(do{$construct->{get}}, 'Get feature `$name`')" if ISA =~ /ro|rw/;

    $construct->{set} = "\$self->FEATURE->{$name}{isa}->validate(\$val, 'Set feature `$name`'); $construct->{set}" if ISA =~ /wo|rw/;
}

# coerce => 1
sub _coerce {
    my ($cls, $name, $type, $construct, $feature) = @_;
    $construct->{coerce} = "\$val = \$self->FEATURE->{$name}{isa}->coerce(\$val); ";
    $construct->{set} = "%(coerce)s$construct->{set}"
}

# default => value
sub _default {
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

# Расширяет
sub _extends {
    my $pkg = shift; my $with = shift;

    my $FEATURE = $pkg->FEATURE;
    my $ASPECT = $pkg->ASPECT;

    # Добавляем наследуемые свойства и атрибуты
	for(@_) {
        eval "require $_";
		die if $@;

		%$FEATURE = (%$FEATURE, %{$_->FEATURE}) if $_->can("FEATURE");
		%$ASPECT = (%$ASPECT, %{$_->ASPECT}) if $_->can("ASPECT");
	}

    my $import_name = $with? 'import_with': 'import_extends';
    for my $mod (@_) {
        my $import = $mod->can($import_name);
        $import->($mod, $pkg) if $import;
    }

    if($with) {
        for my $required (@{"${pkg}::REQUIRES"}) {
            die "Requires `$required` !" if !$pkg->can($required);
        }
    }

    return;
}

# Наследование классов
sub extends {
	my $pkg = caller;

	@{"${pkg}::ISA"} = @_;

    unshift @_, $pkg, 0;
    goto &_extends;
}

# Расширение ролями
sub with {
	my $pkg = caller;

    @{"${pkg}::DOES"} = @_;

    unshift @_, $pkg, 1;
    goto &_extends;
}

# Требуются подпрограммы
sub requires {
    my $pkg = caller;
    push @{"${pkg}::REQUIRES"}, @_;
    return;
}

# Определяет - подключена ли роль
sub does {
    my ($self, $role) = @_;

    my $pkg = ref $self || $self;
    my $does = \@{"${pkg}::DOES"};

    return 1 if $role ~~ $does;
    for(@$does) {
        return 1 if $_->can("does") && $_->does($role);
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

	# атрибуты
	for my $name (ref $property? @$property: $property) {

		die "has: the method $name is already in the package $pkg"
            if $pkg->can($name) && !exists $pkg->ASPECT->{$name};

        my %construct = (
            pkg => $pkg,
            name => $name,
            sub => 'package %(pkg)s {
                sub %(name)s {
                    my ($self, $val) = @_;
				    if(@_>1) { %(set)s } else { %(get)s }
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

        my $ASPECT = $pkg->ASPECT;
        for(my $i=0; $i<@_; $i+=2) {
            my ($aspect, $value) = @_[$i, $i+1];
            my $aspect_sub = $ASPECT->{$aspect};
            die "has: not exists aspect `$aspect`!" if !$aspect_sub;
            $aspect_sub->($pkg, $name, $value, \%construct, $feature);
        }

        my $sub = _resolv($construct{sub}, \%construct);
		eval $sub;
		die if $@;

        $feature->{sub} = $sub;
		$pkg->FEATURE->{$name} = $feature;
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
    my $FEATURE = $cls->FEATURE;

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

Aion — OOP 

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

=head2 aspect ($aspect => sub { ... })

It add aspect to this class or role, and to the classes, who use this role, if it role.

=head1 SUBROUTINES IN CLASSES

=head2 extends (@superclasses)

Extends package other package. It call on each the package method C<import_with> if it exists.

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

=head1 AUTHOR

Yaroslav O. Kosmina LL<mailto:dart@cpan.org>

=head1 LICENSE

⚖ B<GPLv3>
