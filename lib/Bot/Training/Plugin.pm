package Bot::Training::Plugin;

use 5.010;
use Any::Moose;
use Dir::Self;
use File::Spec::Functions qw< catdir catfile >;
use namespace::clean -except => [ qw< meta plugins > ];

sub file {
    my ($self) = @_;

    my $class = ref $self;
    $class =~ s[::][/]g;
    $class =~ s[$][.pm];
    my $path = $INC{$class};

    my $resource = $path;
    $resource =~ s[\.pm$][.trn];
    $resource =~ s[/\K([^/]+)$][lc $1]e;

    return $resource;
}

__PACKAGE__->meta->make_immutable;
