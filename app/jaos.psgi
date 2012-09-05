use 5.10.0;
use RDF::JAOS;
use Plack::Builder;

my $plack_env = $ENV{PLACK_ENV} || '';

my $level = 'trace';
#my $level = 'warn';
#$level = 'debug' unless $plack_env eq 'development';
#$level = 'trace' if $plack_env eq 'debug';

my $app = RDF::JAOS->new(
);

builder {
#    enable 'Debug';
#    enable 'Debug::TemplateToolkit';  

    enable "SimpleLogger";
    enable "Log::Contextual", level => $level;
    $app;
}
