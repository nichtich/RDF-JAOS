package RDF::JAOS;
#ABSTRACT: Just another Ontology server

use 5.10.0;
use File::ShareDir qw(dist_dir);
use File::Spec::Functions qw(catfile);
use Try::Tiny;

use Plack::Builder;
use parent 'Plack::Component';

use RDF::JAOS::Ontology;

=head1 SYNOPSIS

    my $app = RDF::JAOS->new(
        data => $ontology_directory # 'data' by default
    );

    $app; # just start with plackup or another PSGI web server

=head1 DESCRIPTION

JAOS is a simple web application to serve RDF ontologies in OWL and/or RDFS.
It's primary purpose is providing both, the machine-readable version and a nice
browseable interface. 

=cut

sub prepare_app {
    my $self = shift;

    my $data = $self->{data} || 'data';
    die "ontology data directory not found: $data" unless -d $data;

    # load ontologies
    my @files = <$data/*.ttl>;
    $self->{ontologies} = [
        map { 
            RDF::JAOS::Ontology->new( $_ )
        } @files
    ];

    # TODO: log
    # say STDERR @{$self->{ontologies}}.' ontology files';

    my ($templates, $static) = map {
        try { dist_dir('RDF-JAOS',$_) } || catfile('share',$_);
    } qw(templates static);

    my $app = sub { return [404,[],['Not found']]; };

    $self->{app} = builder {

        enable 'Static',
            path => qr{\.(png|js|css)$},
            root => $static;

        enable 'TemplateToolkit',
            INCLUDE_PATH => $templates,
            vars => sub {
               return {
                    ontologies => $self->{ontologies}
               };
            },
            pass_through => 0;
            
        $app;
    };
}

sub call {
    my $self = shift;
    $self->{app}->( @_ );
}

1;
