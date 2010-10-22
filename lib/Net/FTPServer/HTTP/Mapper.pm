package Net::FTPServer::HTTP::Mapper;

sub new { return bless {}, shift }

sub pathToHttp {
    my ($self, $path) = @_;
    return unless $path;

    my $base = 'http://www.desktoprating.com';
    my $otf_uri = URI->new("$base$path",'http');

    $otf_url = 'http://www.teachenglishinasia.net/files/u2/beautiful_pink_water_lily.jpg' if $path eq 'foo';

    return $otf_url;

    # TODO: Fix auth & mapping & tests !!
    # TODO: daemon script & dist details
}

1;
