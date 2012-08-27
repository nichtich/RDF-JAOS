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
use RDF::Lazy qw(0.071);
use Plack::Middleware::TemplateToolkit;
use Plack::Middleware::Rewrite;

=head1 SYNOPSIS

    my $app = RDF::JAOS->new(
        data => $ontology_directory # 'data' by default
    );

    $app; # just start with plackup or another PSGI web server

=head1 DESCRIPTION

JAOS is a simple L<PSGI> web application to serve RDF ontologies in OWL and/or
RDFS.  It's primary purpose is providing both, the machine-readable version and
a nice human-readable interface that can be customized.

In short JAOS reads a set of ontologies from RDF files, wraps them as
L<RDF::JAOS::Ontology> objects and provides them as L<RDF::Lazy> variables to
L<Template>. Just adjust the templates to your needs to present ontologies as
E<you> like. 

=cut

sub prepare_app {
    my $self = shift;
    return if $self->{app}; # TODO: re-read ontologies if changed

    my $ns = RDF::NS->new('any');
    $self->{namespaces} = $ns;

    my $data = $self->{data} || 'data';
    die "ontology data directory not found: $data" unless -d $data;

    # load ontologies (TODO: more formats)
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
            my $ontology = RDF::JAOS::Ontology->new( $file, $prefix => $uri, $ns );
            $self->{ontologies}->{$prefix} = $ontology; 
        } catch {
            log_error { "failed to load ontology file $file: $_" };
        }
    }

    # TODO: customize template directory
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
                my $path = $req->path_info;
                log_info { $path };

                # TODO: fix path and detect suffix for other serializations
                if ( $path =~ qr{/([a-z]+[a-z0-9]+)[/:](.+)} ) {
                    my ($prefix,$element) = ($1,$2,$ext);
                    log_info { "Redirect" };
                    return [302,[Location=>"/$prefix#$prefix:$element"],[]];
                } elsif ( $path =~ qr{/([a-z]+[a-z0-9]+)} ) {
                    my $prefix = $1;

                    $env->{'tt.vars'}->{prefix} = $prefix;

                    my $ont = $self->{ontologies}->{$prefix};
                    if ($ont) {
                        $env->{'tt.template'} = 'ontology.html'; 
                        $env->{'tt.vars'}->{ontology} = $ont;
                    }
                }                
                return $app->($env);
            };
        };

        # TODO: we may want mobile interfaces, don't we?
        
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
