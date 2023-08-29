use common::sense; use open qw/:std :utf8/; use Test::More 0.98; use Carp::Always::Color; sub _mkpath_ { my ($p) = @_; length($`) && !-e $`? mkdir($`, 0755) || die "mkdir $`: $!": () while $p =~ m!/!g; $p } BEGIN { my $t = `pwd`; chop $t; $t .= '/' . __FILE__; my $s = '/tmp/.liveman/perl-aion/aion/'; `rm -fr $s` if -e $s; chdir _mkpath_($s) or die "chdir $s: $!"; open my $__f__, "<:utf8", $t or die "Read $t: $!"; $s = join "", <$__f__>; close $__f__; while($s =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { my ($file, $code) = ($1, $2); $code =~ s/^#>> //mg; open my $__f__, ">:utf8", _mkpath_($file) or die "Write $file: $!"; print $__f__ $code; close $__f__; } } # # NAME
# 
# **Aion** — A postmodern object system for Perl 5, as `Moose` and `Moo`, but with improvements.
# 
# # VERSION
# 
# 0.01
# 
# # SYNOPSIS
# 
subtest 'SYNOPSIS' => sub { 
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

is scalar do {Calc->new(a => 1.1, b => 2)->result}, "3.1", 'Calc->new(a => 1.1, b => 2)->result   # => 3.1';

# 
# # DESCRIPTION
# 
# Aion — OOP framework for create classes with **features**, has **aspects**, **roles** and so on.
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
#>> has type => (is => 'ro+', isa => Str);
#>> has name => (is => 'rw-', isa => Str);
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'has ($name, @aspects)' => sub { 
use lib "lib";
use Animal;

like scalar do {eval { Animal->new }; $@}, qr!Feature type is required\!!, 'eval { Animal->new }; $@    # ~> Feature type is required!';
like scalar do {eval { Animal->new(name => 'murka') }; $@}, qr!Feature name not set in new\!!, 'eval { Animal->new(name => \'murka\') }; $@    # ~> Feature name not set in new!';

my $cat = Animal->new(type => 'cat');
is scalar do {$cat->type}, "cat", '$cat->type   # => cat';

like scalar do {eval { $cat->name }; $@}, qr!Get feature `name` must have the type Str. The it is undef!, 'eval { $cat->name }; $@   # ~> Get feature `name` must have the type Str. The it is undef';

$cat->name("murzik");
is scalar do {$cat->name}, "murzik", '$cat->name  # => murzik';

# 
# ## with
# 
# Add to module roles. It call on each the role method `import_with`.
# 
# File lib/Role/Keys/Stringify.pm:
#@> lib/Role/Keys/Stringify.pm
#>> package Role::Keys::Stringify;
#>> 
#>> use Aion -role;
#>> 
#>> sub keysify {
#>>     my ($self) = @_;
#>>     join ", ", sort keys %$self;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# File lib/Role/Values/Stringify.pm:
#@> lib/Role/Values/Stringify.pm
#>> package Role::Values::Stringify;
#>> 
#>> use Aion -role;
#>> 
#>> sub valsify {
#>>     my ($self) = @_;
#>>     join ", ", map $self->{$_}, sort keys %$self;
#>> }
#>> 
#>> 1;
#@< EOF
# 
# File lib/Class/All/Stringify.pm:
#@> lib/Class/All/Stringify.pm
#>> package Class::All::Stringify;
#>> 
#>> use Aion;
#>> 
#>> with qw/Role::Keys::Stringify Role::Values::Stringify/;
#>> 
#>> has [qw/key1 key2/] => (is => 'rw', isa => Str);
#>> 
#>> 1;
#@< EOF
# 
done_testing; }; subtest 'with' => sub { 
use lib "lib";
use Class::All::Stringify;

my $s = Class::All::Stringify->new(key1=>"a", key2=>"b");

is scalar do {$s->keysify}, "key1, key2", '$s->keysify     # => key1, key2';
is scalar do {$s->valsify}, "a, b", '$s->valsify     # => a, b';

# 
# ## isa ($package)
# 
# Check `$package` is the class what extended this class.
# 
done_testing; }; subtest 'isa ($package)' => sub { 
package Ex::X { use Aion; }
package Ex::A { use Aion; extends qw/Ex::X/; }
package Ex::B { use Aion; }
package Ex::C { use Aion; extends qw/Ex::A Ex::B/ }

is scalar do {Ex::C->isa("Ex::A")}, scalar do{1}, 'Ex::C->isa("Ex::A") # -> 1';
is scalar do {Ex::C->isa("Ex::B")}, scalar do{1}, 'Ex::C->isa("Ex::B") # -> 1';
is scalar do {Ex::C->isa("Ex::X")}, scalar do{1}, 'Ex::C->isa("Ex::X") # -> 1';
is scalar do {Ex::C->isa("Ex::X1")}, scalar do{""}, 'Ex::C->isa("Ex::X1") # -> ""';
is scalar do {Ex::A->isa("Ex::X")}, scalar do{1}, 'Ex::A->isa("Ex::X") # -> 1';
is scalar do {Ex::A->isa("Ex::A")}, scalar do{1}, 'Ex::A->isa("Ex::A") # -> 1';
is scalar do {Ex::X->isa("Ex::X")}, scalar do{1}, 'Ex::X->isa("Ex::X") # -> 1';

# 
# ## does ($package)
# 
# Check `$package` is the role what extended this class.
# 
done_testing; }; subtest 'does ($package)' => sub { 
package Role::X { use Aion -role; }
package Role::A { use Aion; with qw/Role::X/; }
package Role::B { use Aion; }
package Ex::Z { use Aion; with qw/Role::A Role::B/ }

is scalar do {Ex::Z->does("Role::A")}, scalar do{1}, 'Ex::Z->does("Role::A") # -> 1';
is scalar do {Ex::Z->does("Role::B")}, scalar do{1}, 'Ex::Z->does("Role::B") # -> 1';
is scalar do {Ex::Z->does("Role::X")}, scalar do{1}, 'Ex::Z->does("Role::X") # -> 1';
is scalar do {Role::A->does("Role::X")}, scalar do{1}, 'Role::A->does("Role::X") # -> 1';
is scalar do {Role::A->does("Role::X1")}, scalar do{""}, 'Role::A->does("Role::X1") # -> ""';
is scalar do {Ex::Z->does("Ex::Z")}, scalar do{""}, 'Ex::Z->does("Ex::Z") # -> ""';

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
# Aion add universal attributes.
# 
# ## Isa (@signature)
# 
# Attribute `Isa` check the signature the function where it called.
# 
# **WARNING**: use atribute `Isa` slows down the program.
# 
# **TIP**: use aspect `isa` on features is more than enough to check the correctness of the object data.
# 
done_testing; }; subtest 'Isa (@signature)' => sub { 
package Anim {
    use Aion;

    sub is_cat : Isa(Object => Str => Bool) {
        my ($self, $anim) = @_;
        $anim =~ /(cat)/
    }
}

my $anim = Anim->new;

is scalar do {$anim->is_cat('cat')}, scalar do{1}, '$anim->is_cat(\'cat\')    # -> 1';
is scalar do {$anim->is_cat('dog')}, scalar do{""}, '$anim->is_cat(\'dog\')    # -> ""';


like scalar do {eval { Anim->is_cat("cat") }; $@}, qr!Arguments of method `is_cat` must have the type Tuple\[Object, Str\].!, 'eval { Anim->is_cat("cat") }; $@ # ~> Arguments of method `is_cat` must have the type Tuple\[Object, Str\].';
like scalar do {eval { my @items = $anim->is_cat("cat") }; $@}, qr!Returns of method `is_cat` must have the type Tuple\[Bool\].!, 'eval { my @items = $anim->is_cat("cat") }; $@ # ~> Returns of method `is_cat` must have the type Tuple\[Bool\].';

# 
# If use name of type in `@signature`, then call subroutine with this name from current package.
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
