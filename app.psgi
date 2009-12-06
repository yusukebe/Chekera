use Plack::Builder;
use Plack::Request;
use Template;

my $template_config = { INCLUDE_PATH => './templates' };
my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    return root( $req ) if $req->path eq '/';
    [ 404, [ "Content-Type" => "text/plain" ], [ "Not Found" ] ];
};

sub root {
    my $req = shift;
    my $args;
    if( my $playlist = $req->param('playlist') ){
        $playlist =~ s/.*p=([^&]+).*/$1/;
        my $videos = playlist( $playlist );
        $args->{videos} = $videos;
    }
    my $res = $req->new_response(200);
    $res->content_type('text/html');
    $res->body(render('index.html',$args));
    $res->finalize;
}
sub render {
    my ($name, $args) = @_;
    my $tt = Template->new($template_config);
    my $out;
    $tt->process($name,$args, \$out);
    return $out;
}
sub playlist {
    my $playlist_id = shift;
    require XML::Feed;
    my $feed =
      XML::Feed->parse(
        URI->new("http://gdata.youtube.com/feeds/api/playlists/$playlist_id") ) or return [];
    my @videos;
    for my $entry ( $feed->entries() ) {
        my ($id) = $entry->link =~ /\?v=([^&]+)/;
        push( @videos, { title => $entry->title, id => $id } );
    }
    return \@videos;
}

builder {
    enable "Plack::Middleware::Static",
      path => qr/static/,
      root => '.';
    $app;
};
