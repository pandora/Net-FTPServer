package Net::FTPServer::HTTP::Mapper;

sub new { return bless $_[1], $_[0] }

sub pathToHttp {
    my ($self, $resource) = @_;
    return unless $resource;

    my $scheme = $self->config('my_http_server_scheme') || 'http';
    my $server = $self->config('my_http_server') || q{};
    my $port = $self->config('my_http_server_port') || 80;
    return unless $server;

    $server =~ s|//|/|g;
    return "$scheme://$server:$port/$resource";

    # TODO: daemon script & dist details
}

sub config {return $_[0]->{_ftps}->config($_[1]) || q{}}

1;
