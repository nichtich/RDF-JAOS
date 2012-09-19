use RDF::JAOS;
use Plack::Builder;
use v5.12;

my $plack_env = $ENV{PLACK_ENV} || '';
my $level = $plack_env ~~ ['development','debug'] ? 'trace' : 'warn';

my $app = RDF::JAOS->new( data => './data' );

$app = builder {
    enable "SimpleLogger";
    enable "Log::Contextual", level => $level;
    $app;
};

# quick startup 
do {
    use HTTP::Request;
    use HTTP::Message::PSGI;
    my $env = req_to_psgi( HTTP::Request->new(GET => 'http://localhost/') );
    $app->($env);
};

$app;
