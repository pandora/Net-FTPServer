package Net::FTPServer::HTTP::Mapper;

sub new { return bless {}, shift }

sub pathToHttp {
    my ($self, $path) = @_;
    return unless $path;

    return 'http://www.desktoprating.com/wallpapers/nature-wallpapers-pictures/dalia-flower-wallpaper.jpg' if $path eq 'foo';
}

1;
