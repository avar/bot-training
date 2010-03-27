package Bot::Training;

use 5.010;
use autodie qw(open close);
use Any::Moose;
use Any::Moose 'X::Types::'.any_moose() => [qw/Bool Int Str/];
use Module::Pluggable (
    search_path => [ 'Bot::Training' ],
    except      => [ 'Bot::Training::Plugin' ],
);
use List::Util qw< first >;
use namespace::clean -except => [ qw< meta plugins > ];

with any_moose('X::Getopt::Dashes');

has help => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'h',
    cmd_flag      => 'help',
    isa           => Bool,
    is            => 'ro',
    default       => 0,
    documentation => 'This help message',
);

has _go_version => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'v',
    cmd_flag      => 'version',
    documentation => 'Print version and exit',
    isa           => Bool,
    is            => 'ro',
);

has _go_list => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'l',
    cmd_flag      => 'list',
    documentation => 'List the known Bot::Training files. Install Task::Bot::Training to get them all',
    isa           => Bool,
    is            => 'ro',
);

has _go_file => (
    traits        => [ qw/ Getopt / ],
    cmd_aliases   => 'f',
    cmd_flag      => 'file',
    documentation => 'The file to retrieve. Matched case-insensitively against Bot::Training plugins',
    isa           => Str,
    is            => 'ro',
);

sub _new_class {
    my ($self, $class) = @_;

    my $pkg;
    if ($class =~ m[^\+(?<custom_plugin>.+)$]) {
        $pkg = $+{custom_plugin};
    } else {
        # Be fuzzy about includes, e.g. Training::Test, Test or test is OK
        $pkg = first { / : $class /ix }
               sort { length $a <=> length $b }
               $self->plugins;

        unless ($pkg) {
            local $" = ', ';
            my @plugins = $self->plugins;
            die "Couldn't find a class name matching '$class' in plugins '@plugins'";
        }
    }

    if (Any::Moose::moose_is_preferred()) {
        require Class::MOP;
        eval { Class::MOP::load_class($pkg) };
    } else {
        eval qq[require $pkg];
    }
    die $@ if $@;

    return $pkg->new;
}

sub file {
    my ($self, $fuzzy) = @_;

    return $self->_new_class($fuzzy);

}

sub run {
    my ($self) = @_;

    if ($self->_go_version) {
        # Munging strictness because we don't have a version from a
        # Git checkout. Dist::Zilla provides it.
        no strict 'vars';
        my $version = $VERSION // 'dev-git';

        say "bot-training $version";
        return;
    }

    if ($self->_go_list) {
        my @plugins = $self->plugins;
        if (@plugins) {
            say for @plugins;
        } else {
            say "No plugins loaded. Install Task::Bot::Training";
            return 1;
        }
    }
    
    if ($self->_go_file) {
        my $trn = $self->file( $self->_go_file );;
        open my $fh, "<", $trn->file;
        print while <$fh>;
        close $fh;
    }

}

# --i--do-not-exist
sub _getopt_spec_exception { goto &_getopt_full_usage }

# --help
sub _getopt_full_usage {
    my ($self, $usage, $plain_str) = @_;

    # If called from _getopt_spec_exception we get "Unknown option: foo"
    my $warning = ref $usage eq 'ARRAY' ? $usage->[0] : undef;

    my ($use, $options) = do {
        # $plain_str under _getopt_spec_exception
        my $out = $plain_str // $usage->text;

        # The default getopt order sucks, use reverse sort order
        chomp(my @out = split /^/, $out);
        my $opt = join "\n", sort { $b cmp $a } @out[1 .. $#out];
        ($out[0], $opt);
    };
    my $synopsis = do {
        require Pod::Usage;
        my $out;
        open my $fh, '>', \$out;

        no warnings 'once';

        my $hailo = File::Spec->catfile($Hailo::Command::HERE_MOMMY, 'hailo');
        # Try not to fail on Win32 or other odd systems which might have hailo.pl not hailo
        $hailo = ((glob("$hailo*"))[0]) unless -f $hailo;
        Pod::Usage::pod2usage(
            -input => $hailo,
            -sections => 'SYNOPSIS',
            -output   => $fh,
            -exitval  => 'noexit',
        );
        close $fh;

        $out =~ s/\n+$//s;
        $out =~ s/^Usage:/examples:/;

        $out;
    };

    # Unknown option provided
    print $warning if $warning;

    print <<"USAGE";
$use
$options
USAGE

    # Hack: We can't get at our object from here so we have to inspect
    # @ARGV directly.
    say "\n", $synopsis;

    exit 1;
}

__PACKAGE__->meta->make_immutable;

=encoding utf8

=head1 NAME

Bot::Training - Training material for bots like L<Hailo> and L<AI::MegaHAL>

=head1 DESCRIPTION

...

=head1 AUTHORS

E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2010 E<AElig>var ArnfjE<ouml>rE<eth> Bjarmason <avar@cpan.org>

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
