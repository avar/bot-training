package Bot::Training::Plugin;

use 5.010;
use Any::Moose;
use File::ShareDir qw< :ALL >;
use File::Spec::Functions qw< catdir catfile >;
use namespace::clean -except => 'meta';

sub file {
    my ($self) = @_;

    my $class = ref $self;
    my ($last) = $class =~ m[::([^:]+)$];
    my $file = module_file( $class, lc($last) . '.trn');

    return $file;
}

__PACKAGE__->meta->make_immutable;
