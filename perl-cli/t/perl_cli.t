use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Cwd;
use File::Spec;
use FindBin;

my $script = Cwd::abs_path(File::Spec->catfile($FindBin::Bin, '..', 'perl_cli.pl'));

my $dir = tempdir(CLEANUP => 1);
my $prev = getcwd();
chdir $dir or die $!;

require $script;
our $history_file; # from script

save_history([{ role => 'user', content => 'hi' }]);
my $loaded = load_history();
is_deeply($loaded, [{ role => 'user', content => 'hi' }], 'save and load history');

clear_history();
ok(!-e $main::history_file, 'history file removed');

# load history when file missing and empty
my $msgs = load_history();
is_deeply($msgs, [], 'load_history with missing file returns empty');

open my $fh, '>', $main::history_file or die $!;
close $fh;
$msgs = load_history();
is_deeply($msgs, [], 'load_history with empty file returns empty');

chdir $prev or die $!;

done_testing();
