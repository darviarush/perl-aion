package Aion;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.01";

use Scalar::Util qw//;

# вызывается из другого пакета, для импорта данного
sub import {
	my ($cls, $attr) = @_;
	my ($pkg, $path) = caller;

    if($attr ne '-role') {
	    *{"${pkg}::new"} = \&new;
        *{"${pkg}::extends"} = \&extends;
    }

	*{"${pkg}::with"} = \&with;
	*{"${pkg}::upgrade"} = \&upgrade;
	*{"${pkg}::has"} = \&has;
	*{"${pkg}::ATTRIBUTE"} = \&ATTRIBUTE;
	%{"${pkg}::ATTRIBUTE"} = ();
}

# Расширяет
sub _extends {
    my ($pkg, $import_name) = @_;

	for(@_) {  # подключаем
		eval "require $_";
		die if $@;
	}

    my $ATTRIBUTE = $pkg->ATTRIBUTE;

    # Добавляем наследуемые атрибуты
	for(@_) {
		next if !$_->can("ATTRIBUTE");
		my $ATTRIBUTE_EXTEND = $_->ATTRIBUTE;
		while(my ($k, $v) = each %$ATTRIBUTE_EXTEND) {
			$ATTRIBUTE->{$k} = $v;
		}
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

    _extends($pkg, "import_extends");
}

# Расширение
sub with {
	my $pkg = caller;
    _extends($pkg, "import_with");
}

# создаёт свойство
sub has(@) {
	my $property = shift;

    return exists $property->{$_[0]} if Scalar::Util::blessed($property);

	my $pkg = caller;

	# атрибуты
	for my $name (ref $property? @$property: $property) {

		die "has: the method $name is already in the package $pkg"
            if $pkg->can($name) && !exists ${"${pkg}::ATTRIBUTE"}{$name};

		my %opt = @_;

		die "has: property $name has a strange is='$opt{is}'" if $opt{is} !~ /^(ro|rw)[+-]?$/;

		for my $key (keys %opt) {
			die "has: свойство $name имеет странный атрибут '$key'" if $key !~ /^(is|isa|default|coerce)$/;
		}

		$opt{name} = $name;
		$opt{ro} = $opt{is} =~ m/o/? 1: 0;
		$opt{rw} = $opt{is} =~ m/w/? 1: 0;
		$opt{input} = $opt{is} !~ m/-/? 1: 0;
		$opt{required} = $opt{is} =~ m/\+/? 1: 0;
		
		if(defined $opt{isa}) {
			die "has: isa у свойства $name должна быть Aion::View::Type"
                if !UNIVERSAL::isa($opt{isa}, 'Aion::View::Type');
		}

		$opt{coerce} = $opt{isa} if $opt{coerce} == 1;

		die "has: from у свойства $name никогда не сработает, т.к. это не свойство ввода!" if exists $opt{from} && !$opt{input};
		die "has: in у свойства $name никогда не сработает, т.к. это не свойство ввода!" if exists $opt{in} && !$opt{input};

		$opt{lazy} = ref $opt{default} eq "CODE";
		$opt{is_natural_default} = exists $opt{default} && !$opt{lazy};

		die "has: default у свойства $name никогда не сработает, т.к. свойство обязательно!" if exists $opt{default} && $opt{required};
		#die "has: coerce у свойства $name никогда не сработает, т.к. свойство не имеет сеттера!" if $opt{coerce} && $opt{ro} && ;

		if($opt{lazy}) {
			Sub::Util::set_subname "${pkg}::${name}__DEFAULT__" => $opt{default};
			
			$opt{default} = wrapsub $opt{default} => \&_view_telemetry if $main_config::view_telemetry;
		}
		
		# Валидируем default, который будет устанавливаться в атрибуты
		$opt{isa}->validate($opt{default}, $name, $pkg) if $opt{is_natural_default} && $opt{isa};

		# Когда осуществлять проверки: 
		#   ro - только при выдаче
		#   wo - только при установке
		#   rw - при выдаче и учтановке
		#   no - никогда не проверять
		# my $isa_mode = $main_config::aion_view_isa_mode // "rw";
		# my @isa_mode = qw/ro wo rw no/;
		# do { local $, = ", "; die "\$main_config::aion_view_isa_mode должен быть [@isa_mode], а не $isa_mode" } unless $isa_mode ~~ \@isa_mode;

		my $coerce; my $isa;
		$coerce = "\$val = \$ATTRIBUTE{$name}{coerce}->coerce(\$val); " if $opt{coerce};
		$isa = "\$ATTRIBUTE{$name}{isa}->validate(\$val, '$name', __PACKAGE__); " if $opt{isa};
		# my $ro_isa = $isa_mode ~~ [qw/ro rw/]? $isa: "";
		# my $wo_isa = $isa_mode ~~ [qw/ro rw/]? $isa: "";

		my $set = $opt{ro}? "die 'has: $name is ro'":
			"$coerce$isa\$self->{$name} = \$val; \$self";
		my $get = join "", (
			$opt{lazy}? "if(exists \$self->{$name}) { \$val = \$self->{$name} } else {
				\$val = \$ATTRIBUTE{$name}{default}->(\$self);$coerce
				\$self->{$name} = \$val;
			}; ":
				"\$val = \$self->{$name}; "
		),
		$isa, "\$val";


		my $DEBUG = 0;
		if($DEBUG) {
			$set = "print ref \$self, '#$name ⟵ ', \"\\n\"; $set";
			$get = "my \$x=$get; print ref \$self, '#$name ⟶ ', length(\$x)<25? \$x: substr(\$x, 0, 25) . '…', \"\\n\"; \$x";
		}
		#$get = "trace '$name'; $get";

		eval "package ${pkg} {
			our %ATTRIBUTE;
			sub $name {
				my (\$self, \$val) = \@_;
				if(\@_>1) { $set } else { $get }
			}
		}";
		die if $@;

		#eval "package ${pkg} { sub has_$name { exists \$_[0]->{$name} } }";
		#die if $@;

		${"${pkg}::ATTRIBUTE"}{$name} = \%opt;
	}
	return;
}

# конструктор
sub new {
	my ($cls, %value) = @_;
	
	my ($self, @errors) = $cls->create_from_params(%value);

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

	while(my ($name, $opt) = each %{$cls->ATTRIBUTE}) {

		if(exists $value{$name}) {
			my $val = delete $value{$name};
			
			if($opt->{input}) {
				$val = $opt->{coerce}->coerce($val) if $opt->{coerce};

				push @errors, $opt->{isa}->detail($val, $name) if $opt->{isa} && !$opt->{isa}->include($val);
				$self->{$name} = $val;
			}
			else {
				push @errors, "Свойство $name нельзя устанавливать через конструктор!";
			}
		} else {
			$self->{$name} = $opt->{default} if $opt->{is_natural_default};
			push @required, $name if $opt->{required};
		}

	}

	do {local $" = ", "; unshift @errors, "Свойства @required — обязательны!"} if @required > 1;
	unshift @errors, "Свойство @required — обязательно!" if @required == 1;
	
	my @fakekeys = sort keys %value;
	unshift @errors, "@fakekeys — нет свойства!" if @fakekeys == 1;
	do {local $" = ", "; unshift @errors, "@fakekeys — нет свойств!"} if @fakekeys > 1;

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

