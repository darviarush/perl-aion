use common::sense; use open qw/:std :utf8/;  use Carp qw//; use Cwd qw//; use File::Basename qw//; use File::Find qw//; use File::Slurper qw//; use File::Spec qw//; use File::Path qw//; use Scalar::Util qw//;  use Test::More 0.98;  use String::Diff qw//; use Data::Dumper qw//; use Term::ANSIColor qw//;  BEGIN { 	$SIG{__DIE__} = sub { 		my ($msg) = @_; 		if(ref $msg) { 			$msg->{STACKTRACE} = Carp::longmess "?" if "HASH" eq Scalar::Util::reftype $msg; 			die $msg; 		} else { 			die Carp::longmess defined($msg)? $msg: "undef" 		} 	}; 	 	my $t = File::Slurper::read_text(__FILE__); 	 	my @dirs = File::Spec->splitdir(File::Basename::dirname(Cwd::abs_path(__FILE__))); 	my $project_dir = File::Spec->catfile(@dirs[0..$#dirs-2]); 	my $project_name = $dirs[$#dirs-2]; 	my @test_dirs = @dirs[$#dirs-2+2 .. $#dirs];  	$ENV{TMPDIR} = $ENV{LIVEMAN_TMPDIR} if exists $ENV{LIVEMAN_TMPDIR};  	my $dir_for_tests = File::Spec->catfile(File::Spec->tmpdir, ".liveman", $project_name, join("!", @test_dirs, File::Basename::basename(__FILE__))); 	 	File::Find::find(sub { chmod 0700, $_ if !/^\.{1,2}\z/ }, $dir_for_tests), File::Path::rmtree($dir_for_tests) if -e $dir_for_tests; 	File::Path::mkpath($dir_for_tests); 	 	chdir $dir_for_tests or die "chdir $dir_for_tests: $!"; 	 	push @INC, "$project_dir/lib", "lib"; 	 	$ENV{PROJECT_DIR} = $project_dir; 	$ENV{DIR_FOR_TESTS} = $dir_for_tests; 	 	while($t =~ /^#\@> (.*)\n((#>> .*\n)*)#\@< EOF\n/gm) { 		my ($file, $code) = ($1, $2); 		$code =~ s/^#>> //mg; 		File::Path::mkpath(File::Basename::dirname($file)); 		File::Slurper::write_text($file, $code); 	} }  my $white = Term::ANSIColor::color('BRIGHT_WHITE'); my $red = Term::ANSIColor::color('BRIGHT_RED'); my $green = Term::ANSIColor::color('BRIGHT_GREEN'); my $reset = Term::ANSIColor::color('RESET'); my @diff = ( 	remove_open => "$white\[$red", 	remove_close => "$white]$reset", 	append_open => "$white\{$green", 	append_close => "$white}$reset", );  sub _string_diff { 	my ($got, $expected, $chunk) = @_; 	$got = substr($got, 0, length $expected) if $chunk == 1; 	$got = substr($got, -length $expected) if $chunk == -1; 	String::Diff::diff_merge($got, $expected, @diff) }  sub _struct_diff { 	my ($got, $expected) = @_; 	String::Diff::diff_merge( 		Data::Dumper->new([$got], ['diff'])->Indent(0)->Useqq(1)->Dump, 		Data::Dumper->new([$expected], ['diff'])->Indent(0)->Useqq(1)->Dump, 		@diff 	) }  # package Aion::Pleroma;
# # Контейнер для эонов (сервисов)
# 
# use common::sense;
# 
# use config {
# 	INI => 'etc/annotation/eon.ann',
# 	PLEROMA => {},
# 	AUTOWARE => 1,
# };
# 
# use Aion;
# 
# # Файл с аннотациями
# has ini => (is => 'ro', isa => Maybe[Str], default => INI);
# 
# # Конфигурация: ключ => класс#метод_класса
# has pleroma => (is => 'ro', isa => HashRef[Str], default => sub {
# 	my ($self) = @_;
# 	
# 	my %pleroma = (%{&PLEROMA}, 'Aion::Pleroma' => 'Aion::Pleroma#new');
# 	return \%pleroma unless defined $self->ini and -e $self->ini;
# 
# 	open my $f, '<:utf8', INI or die "Not open ${\$self->ini}: $!";
# 	while(<$f>) {
# 		close($f), die "${\$self->ini} corrupt at line $.: $_" unless /^([\w:]+)#(\w*),\d+=(.*)$/;
# 		my ($pkg, $sub, $key) = ($1, $2, $3);
# 		my $action = join "#", $pkg, $sub || 'new';
# 
# 		$key = $key ne ""? $key: ($sub? "$pkg#$sub": $pkg);
# 
# 		close($f), die "The eon $key is $pleroma{$key}, but added other $action" if exists $pleroma{$key};
# 
# 		$pleroma{$key} = $action;
# 	}
# 	close $f;
# 
# 	\%pleroma
# });
# 
# # Совокупность порождённых эонов (сервисов)
# has eon => (is => 'ro', isa => HashRef[Object], lazy => 0, default => sub { +{'Aion::Pleroma' => shift} });
# 
# # Получить эон из контейнера
# sub get {
# 	my ($self, $key) = @_;
# 	
# 	my $eon = $self->{eon}{$key};
# 	return $eon if $eon;
# 	
# 	my $config = $self->pleroma->{$key};
# 	if($config) {
# 		my ($pkg, $method) = $config =~ /#/? ($`, $'): ();
# 		eval "require $pkg" or die unless $pkg->can('new') || $pkg->can('does');
# 		$self->{eon}{$key} = $pkg->$method;
# 	}
# 	elsif(AUTOWARE and $key =~ /^[\w:]+(#\w+)?$/) { $self->autoware($key)->get($key) }
# 	else { undef }
# }
# 
# # Получить эон из контейнера или исключение, если его там нет
# sub resolve {
# 	my ($self, $key) = @_;
# 	
# 	$self->get($key) // die "$key is'nt eon!"
# }
# 
# # Добавить в плерому пакет
# sub autoware {
# 	my ($self, $action, $key) = @_;
# 	my ($pkg, $sub) = $action =~ /#/? ($`, $'): ($action, 'new');
# 	$action = "$pkg#$sub";
# 	$key //= $action =~ /#new$/? $pkg: $action;
# 
# 	if(my $action_exists = $self->pleroma->{$key}) {
# 		die "Added eon $key twice, with $action ne $action_exists" if $action_exists ne $action;
# 	}
# 	else {
# 		$self->pleroma->{$key} = $action;
# 	}
# 	$self
# }
# 
# 1;
# 
# __END__
# 
# =encoding utf-8
# 
# =head1 NAME
# 
# Aion::Pleroma - container of aeons
# 
# =head1 SYNOPSIS
# 
# 	use Aion::Pleroma;
# 	
# 	my $pleroma = Aion::Pleroma->new;
# 	
# 	$pleroma->get('user') # -> undef
# 	$pleroma->resolve('user') # @-> user is'nt eon!
# 
# =head1 DESCRIPTION
# 
# Implements the dependency container pattern.
# 
# An eon is created when requesting from a container via the C<get> or C<resolve> method, or via the C<eon> aspect as a lazy C<default>. Laziness can be canceled via the C<lazy> aspect.
# 
# The container is in the C<$Aion::pleroma> variable and can be replaced with C<local>.
# 
# The configuration for creating eons is obtained from the C<PLEROMA> config and the annotation file (created by the C<Aion::Annotation> package). The annotation file can be replaced via the C<INI> config.
# 
# =head1 FEATURES
# 
# =head2 ini
# 
# Annotation file.
# 
# 	Aion::Pleroma->new->ini # => etc/annotation/eon.ann
# 
# =head2 pleroma
# 
# Configuration: key => 'class#class_method'.
# 
# File lib/Ex/Eon/AnimalEon.pm:
# 
# 	package Ex::Eon::AnimalEon;
# 	#@eon
# 	
# 	use common::sense;
# 	
# 	use Aion;
# 	 
# 	has role => (is => 'ro');
# 	
# 	#@eon ex.cat
# 	sub cat { __PACKAGE__->new(role => 'cat') }
# 	
# 	#@eon
# 	sub dog { __PACKAGE__->new(role => 'dog') }
# 	
# 	1;
# 
# File etc/annotation/eon.ann:
# 
# 	Ex::Eon::AnimalEon#,2=
# 	Ex::Eon::AnimalEon#cat,10=ex.cat
# 	Ex::Eon::AnimalEon#dog,13=Ex::Eon::AnimalEon#dog
# 
# 
# 
# 	Aion::Pleroma->new->pleroma # --> {"Ex::Eon::AnimalEon" => "Ex::Eon::AnimalEon#new", "Ex::Eon::AnimalEon#dog" => "Ex::Eon::AnimalEon#dog", "ex.cat" => "Ex::Eon::AnimalEon#cat", "Aion::Pleroma" => "Aion::Pleroma#new"}
# 
# =head2 eon
# 
# The totality of generated eons.
# 
# 	my $pleroma = Aion::Pleroma->new;
# 	
# 	$pleroma->eon # --> { "Aion::Pleroma" => $pleroma }
# 	my $cat = $pleroma->resolve('ex.cat');
# 	$pleroma->eon # --> { "ex.cat" => $cat, "Aion::Pleroma" => $pleroma }
# 
# =head1 SUBROUTINES
# 
# =head2 get ($key)
# 
# Receive an eon from the container.
# 
# 	my $pleroma = Aion::Pleroma->new;
# 	$pleroma->get('') # -> undef
# 	$pleroma->get('Ex::Eon::AnimalEon#dog')->role # => dog
# 
# =head2 resolve ($key)
# 
# Get an eon from the container or an exception if it is not there.
# 
# 	my $pleroma = Aion::Pleroma->new;
# 	$pleroma->resolve('e.ibex') # @=> e.ibex is'nt eon!
# 	$pleroma->resolve('Ex::Eon::AnimalEon#dog')->role # => dog
# 
# =head2 autoware ($action, [$key])
# 
# Add a key to the pleroma.
# 
# File lib/Ex/Eon/AstroEon.pm:
# 
# 	package Ex::Eon::AstroEon;
# 	use common::sense;
# 	use Aion;
# 	
# 	has role => (is => 'ro', default => 'upiter');
# 	sub mars { __PACKAGE__->new(role => 'mars') }
# 	sub venus { __PACKAGE__->new(role => 'venus') }
# 	
# 	1;
# 
# 
# 
# 	my $pleroma = Aion::Pleroma->new;
# 	$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
# 	$pleroma->autoware('Ex::Eon::AstroEon#mars', 'ex.mars')->get('ex.mars')->role # => mars
# 	$pleroma->autoware('Ex::Eon::AstroEon#venus')->get('Ex::Eon::AstroEon#venus')->role # => venus
# 	
# 	$pleroma->autoware('Ex::Eon::AstroEon')->get('Ex::Eon::AstroEon')->role # => upiter
# 	$pleroma->autoware('Ex::Eon::AstroEon#mars', 'Ex::Eon::AstroEon#venus') # @-> Added eon Ex::Eon::AstroEon#venus twice, with Ex::Eon::AstroEon#mars ne Ex::Eon::AstroEon#venus
# 
# =head1 AUTHOR
# 
# Yaroslav O. Kosmina L<mailto:dart@cpan.org>
# 
# =head1 LICENSE
# 
# ⚖ B<GPLv3>
# 
# =head1 COPYRIGHT
# 
# The Aion::Pleroma module is copyright © 2025 Yaroslav O. Kosmina. Rusland. All rights reserved.

::done_testing;
