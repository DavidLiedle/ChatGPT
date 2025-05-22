use strict;
use warnings;
use JSON::PP;
use HTTP::Tiny;
use File::Spec;

our $history_file = 'history.json';

sub load_history {
    return [] unless -e $history_file;
    open my $fh, '<', $history_file or return [];
    local $/;
    my $data = <$fh> // '';
    close $fh;
    return [] if $data =~ /^\s*$/;
    my $json = JSON::PP->new->decode($data);
    return $json;
}

sub save_history {
    my ($msgs) = @_;
    open my $fh, '>', $history_file or die $!;
    print $fh JSON::PP->new->ascii->pretty->encode($msgs);
    close $fh;
}

sub call_openai {
    my ($msgs, $api_key) = @_;
    my $ua = HTTP::Tiny->new();
    my $body = JSON::PP->new->encode({ model => 'gpt-4o', messages => $msgs });
    my $resp = $ua->post(
        'https://api.openai.com/v1/chat/completions',
        {
            headers => {
                'Authorization' => "Bearer $api_key",
                'Content-Type'  => 'application/json',
            },
            content => $body,
        }
    );
    die "API error: $resp->{status} $resp->{reason}" unless $resp->{success};
    my $parsed = JSON::PP->new->decode($resp->{content});
    die 'no choices returned' unless @{$parsed->{choices} || []};
    return $parsed->{choices}[0]{message}{content};
}

sub chat {
    my ($api_key) = @_;
    my $history = load_history();
    print "Enter 'exit' to quit.\n";
    while (1) {
        print '> ';
        defined(my $line = <STDIN>) or last;
        chomp $line;
        my $text = $line;
        $text =~ s/^\s+|\s+$//g;
        last if $text eq 'exit' || $text eq 'quit';
        push @$history, { role => 'user', content => $text };
        my $reply = eval { call_openai($history, $api_key) };
        if ($@) { warn "Error: $@"; last; }
        print "$reply\n";
        push @$history, { role => 'assistant', content => $reply };
        save_history($history);
    }
}

sub print_history {
    my $history = load_history();
    for my $m (@$history) {
        print "$m->{role}: $m->{content}\n";
    }
}

sub clear_history {
    unlink $history_file if -e $history_file;
}

sub main {
    if (!@ARGV) {
        print "Usage: [chat|history|clear]\n";
        return;
    }
    my $api_key = $ENV{OPENAI_API_KEY} // '';
    if ($api_key eq '') {
        print "OPENAI_API_KEY not set\n";
        return;
    }
    my $cmd = shift @ARGV;
    if ($cmd eq 'chat') {
        chat($api_key);
    } elsif ($cmd eq 'history') {
        print_history();
    } elsif ($cmd eq 'clear') {
        clear_history();
    } else {
        print "Unknown command\n";
    }
}

main() unless caller;

1;
