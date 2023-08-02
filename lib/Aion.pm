package Aion;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Scalar::Util qw/blessed/;
use Sub::Util qw/set_subname/;

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

    # Свойства объекта
	constant->import("${pkg}::FEATURE" => {});

    # Атрибуты для has
	constant->import("${pkg}::ATTRIBUTE" => {
        is => \&_is,
        isa => \&_isa,
        coerce => \&_coerce,
        default => \&_default,
    });
}

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
    die "has: $name - isa maybe Aion::View::Type"
        if !UNIVERSAL::isa($isa, 'Aion::View::Type');

    $feature->{isa} = $isa;

    $construct->{get} = "\$self->FEATURE->{$name}{isa}->validate(do{$construct->{get}}, '$name')" if ISA =~ /ro|rw/;

    $construct->{set} = "\$self->FEATURE->{$name}{isa}->validate(\$val, '$name'); $construct->{set}" if ISA =~ /wo|rw/;
}

# coerce => 1|Coerce
sub _coerce {
    my ($cls, $name, $type, $construct, $feature) = @_;
    
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
    my $pkg = shift; my $import_name = shift;

    my $FEATURE = $pkg->FEATURE;
    my $ATTRIBUTE = $pkg->ATTRIBUTE;

    # Добавляем наследуемые свойства и атрибуты
	for(@_) {
        eval "require $_";
		die if $@;

		%$FEATURE = (%$FEATURE, %{$_->FEATURE}) if $_->can("FEATURE");
		%$ATTRIBUTE = (%$ATTRIBUTE, %{$_->ATTRIBUTE}) if $_->can("ATTRIBUTE");
	}

    # Запускаем
    for my $mod (@_) {
        my $import = $mod->can($import_name);
        $import->($mod, $pkg) if $import;
    }

    return;
}

# Наследование
sub extends {
	my $pkg = caller;

	@{"${pkg}::ISA"} = @_;

    unshift @_, $pkg, "import_extends";
    goto &_extends;
}

# Расширение
sub with {
	my $pkg = caller;
    unshift @_, $pkg, "import_with";
    goto &_extends;
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
            if $pkg->can($name) && !exists $pkg->ATTRIBUTE->{$name};

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

        my $ATTRIBUTE = $pkg->ATTRIBUTE;
        for(my $i=0; $i<@_; $i+=2) {
            my ($attribute, $value) = @_[$i, $i+1];
            my $attribute_sub = $ATTRIBUTE->{$attribute};
            die "has: not exists attribute `$attribute`!" if !$attribute_sub;
            $attribute_sub->($pkg, $name, $value, \%construct, $feature);
        }

        my $sub = $construct{sub};
        $sub =~ s!%\((\w+)\)s!$construct{$1} // die "has: not construct `$1`\!"!ge;
		eval $sub;
		die if $@;

        $feature->{sub} = $sub;
		$pkg->FEATURE->{$name} = $feature;
	}
	return;
}

# конструктор
sub new {
	my $cls = shift;
	
	my ($self, @errors) = $cls->create_from_params(@_);

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

				push @errors, $feature->{isa}->detail($val, $name)
                    if ISA =~ /w/ && $feature->{isa} && !$feature->{isa}->include($val);
				$self->{$name} = $val;
			}
			else {
				push @errors, "has: feature $name not set in new!";
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

Aion - It's new $module

=head1 SYNOPSIS

    use Aion;

=head1 DESCRIPTION

Aion is ...

=head1 LICENSE

Copyright (C) Yaroslav O. Kosmina.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Yaroslav O. Kosmina E<lt>darviarush@mail.ruE<gt>

=cut

