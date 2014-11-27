use Test::More;
use Cwd;
use inc();

my @orig = @INC;

my @lib = inc->list('lib');

is scalar(@lib), 1, "'lib' object returns one value";
my $want_lib = Cwd::abs_path('lib');
is $lib[0], Cwd::abs_path('lib'), "'lib' object returns 'lib'";

my @inc = inc->list('lib', 'INC');
is scalar(@inc), @orig + 1, 'Add one more value';

my $got_inc = join "\n", @inc;
my $want_inc = join "\n", Cwd::abs_path('lib'), @orig;
is $got_inc, $want_inc, 'Add lib to front';

done_testing;
