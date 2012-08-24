package RDF::JAOS;
#ABSTRACT: Just another Ontology server

use 5.10.0;
use File::ShareDir qw(dist_dir);
use File::Slurp qw(read_file);
use File::Spec::Functions qw(catfile splitpath);
use Try::Tiny;
use Log::Contextual qw(:log);

use Plack::Builder;
use parent 'Plack::Component';

use RDF::JAOS::Ontology;
use RDF::NS;
use RDF::Lazy;
use Plack::Middleware::TemplateToolkit;

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
    return if $self->{app};

    $self->{namespaces} = RDF::NS->new('any');

    my $data = $self->{data} || 'data';
    die "ontology data directory not found: $data" unless -d $data;

    # load ontologies
    $self->{ontologies} = { }; 
    foreach my $file (<$data/*.ttl>) {
        my ($v,$d,$f) = splitpath($file);
        try {
            log_info { "load ontology file $file" };
            die "invalid prefix in filename\n" unless $f =~ /^([a-z]+[a-z0-9]+).ttl$/;
            my $prefix = $1;
            my $uri;
            foreach( read_file( $file ) ) {
                next unless /\@prefix\s+$prefix:\s+<(.+)>/;
                $uri = $1;
                last;
            }
            my $ontology = RDF::JAOS::Ontology->new( $file, $prefix => $uri );
            $self->{ontologies}->{$prefix} = $ontology; 
            $self->{namespaces}->{$prefix} = $ontology->{base};
        } catch {
            log_error { "failed to load ontology file $file: $_" };
        }
    }

    my ($templates, $static) = map {
        try { dist_dir('RDF-JAOS',$_) } || catfile('share',$_);
    } qw(templates static);

    $self->{app} = builder {
        enable 'Static',
            path => qr{\.(png|js|css)$},
            root => $static;

        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                log_info { $req->path_info };
                if ( $req->path_info =~ qr{/([a-z]+[a-z0-9]+)} ) {
                    my $prefix = $1;
                    $env->{'tt.vars'}->{prefix} = $prefix;
                    my $ont = $self->{ontologies}->{$1};
                    if ($ont) {
                        $env->{'tt.template'} = 'ontology.html'; 
                        my $graph = RDF::Lazy->new(
                            rdf => $ont->{model},
                            # FIXME in RDF::Lazy: support RDF::NS instead of NamespaceMap
                            namespaces => { %{$self->{namespaces}} },
                        );
                        $env->{'tt.vars'}->{ograph} = $graph;
                        $env->{'tt.vars'}->{obase} = $graph->resource( $ont->{base} );
                    }
                }                
                return $app->($env);
            };
        };

        Plack::Middleware::TemplateToolkit->new(
            INCLUDE_PATH => $templates,
            404 => '404.html',
            vars => sub {
               return {
                    ontologies => $self->{ontologies}
               };
            },
            pass_through => 0,
        );
    };
}

sub call {
    my $self = shift;
    $self->{app}->( @_ );
}

1;
