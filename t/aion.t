use common::sense; use open qw/:std :utf8/; use Test::More 0.98; use Carp::Always::Color; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion/aion/'; `rm -fr $s` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; $s = join "", <$__f__>; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# **Aion** — A postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements.
# 
# # VERSION
# 
# 1.0
# 
# # SYNOPSIS
# 
# File lib/Calc.pm:
#@> lib/Calc.pm
#>> package Calc;
#>> 
#>> use Aion;
#>> 
#>> has a => (is => 'ro+', isa => Num);
#>> has b => (is => 'ro+', isa => Num);
#>> has op => (is => 'ro', isa => Enum[qw/+ - * \/ **/], default => '+');
#>> 
#>> sub result {
#>>     my ($self) = @_;
#>>     eval "${\ $self->a} ${\ $self->op} ${\ $self->b}"
#>> }
#>> 
#>> 1;
#@< EOF
# 
subtest 'SYNOPSIS' => sub { 
use Calc;

is scalar do {Calc->new(a => 1, b => 2)->result}, "3", 'Calc->new(a => 1, b => 2)->result   # => 3';

# 
# # DESCRIPTION
# 
# 
# 
# # SUBROUTINES
# 
# `use Aion` include in module types from `Aion::Types` and next subroutines:
# 
# ## has ($name, @attributes)
# 
# Make method for get/set feature (property) of the class.
# 
# File lib/Animal.pm:
#@> lib/Animal.pm
#>> package Animal;
#>> use Aion;
#>> 
#>> has 
#>> 
#>> 1;
#@< EOF
# 
# ## extends (@superclasses)
# 
# Extends package other package. It call on each the package method `import_with`.
# 
# ## with
# 
# Add to module roles. It call on each the role method `import_with`.
# 
# # METHODS
# 
# `use Aion` include in module next methods:
# 
# ## new (%parameters)
# 
# The constructor.
# 
# ## has ($property)
# 
# It check what property is set.
# 
# # AUTHOR
# 
# Yaroslav O. Kosmina [dart@cpan.org](mailto:dart@cpan.org)
# 
# # LICENSE
# 
# ⚖ **GPLv3**
	done_testing;
};

done_testing;
