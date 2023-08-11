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
use lib "lib";
use Calc;

is scalar do {Calc->new(a => 1.1, b => 2)->result}, "3.1", 'Calc->new(a => 1.1, b => 2)->result   # => 3.1';

# 
# # DESCRIPTION
# 
# Aion — OOP 
# 
# Properties declared via `has` are called **features**.
# 
# And `is`, `isa`, `default` and so on in `has` are called **aspects**.
# 
# In addition to standard aspects, roles can add their own aspects using subroutine `aspect`.
# 
# # SUBROUTINES IN CLASSES AND ROLES
# 
# `use Aion` include in module types from `Aion::Types` and next subroutines:
# 
# ## has ($name, @aspects)
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
# ## with
# 
# Add to module roles. It call on each the role method `import_with`.
# 
# ## aspect ($aspect => sub { ... })
# 
# It add aspect to this class or role, and to the classes, who use this role, if it role.
# 
# # SUBROUTINES IN CLASSES
# 
# ## extends (@superclasses)
# 
# Extends package other package. It call on each the package method `import_with` if it exists.
# 
# # SUBROUTINES IN ROLES
# 
# ## requires (@subroutine_names)
# 
# It add aspect to the classes, who use this role.
# 
# # METHODS
# 
# ## has ($feature)
# 
# It check what property is set.
# 
# ## clear ($feature)
# 
# It check what property is set.
# 
# 
# # METHODS IN CLASSES
# 
# `use Aion` include in module next methods:
# 
# ## new (%parameters)
# 
# The constructor.
# 
# # ATTRIBUTES
# 
# Aion add universal atributes.
# 
# ## Isa (@signature)
# 
done_testing; }; subtest 'Isa (@signature)' => sub { 
package Anim {
    use Aion;

    sub is_cat : Isa(Self => Str => Bool) {
        my ($self, $anim) = @_;
        $anim =~ /(cat)/
    }
}

my $anim = Anim->new;

is scalar do {$anim->is_cat('cat')}, scalar do{1}, '$anim->is_cat(\'cat\')    # -> 1';
is scalar do {$anim->is_cat('dog')}, scalar do{""}, '$anim->is_cat(\'dog\')    # -> ""';


like scalar do {eval { Anim->is_cat("cat") }; $@}, qr!123!, 'eval { Anim->is_cat("cat") }; $@ # ~> 123';
like scalar do {eval { my @items = $anim->is_cat("cat") }; $@}, qr!123!, 'eval { my @items = $anim->is_cat("cat") }; $@ # ~> 123';


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