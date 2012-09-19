package RDF::JAOS;
#ABSTRACT: Just another Ontology server

use 5.10.0;
use File::ShareDir qw(dist_dir);
use File::Slurp qw(read_file);
use File::Spec::Functions qw(catfile splitpath);
use Try::Tiny;
use IO::Dir;
use Log::Contextual qw(:log);

use Plack::Builder;
use parent 'Plack::Component';

use RDF::JAOS::Ontology;
use RDF::NS;
use RDF::Lazy qw(0.071);

use Plack::Middleware::TemplateToolkit;
use Plack::Middleware::Negotiate;

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

sub load_ontologies {
    my $self = shift;
    $self->{ontologies} = { }; 

    my $data = $self->{data} || 'data';
    my $dir = IO::Dir->new($data) // do {
        log_error { "ontology data directory not found: $data" };
        return;
    };

    log_info { "loading ontologies from $data" };

    while (defined($file = $dir->read)) {
        next unless $file  =~ /^([a-z][a-z0-9]*)\.(owl\.|rdf\.)?(ttl|rdf|xml|n3)$/;
        my $prefix = $1;

        try {
            my $ontology = RDF::JAOS::Ontology->new( 
                from       => $data.'/'.$file, 
                prefix     => $prefix,
                namespaces => $self->{namespaces},
            );

            log_info { "$file: ".($ontology->me->dct_title || $ontology->me->dc_title) };

            $self->{ontologies}->{ $prefix } = $ontology;
        } catch {
            log_error { "failed to load ontology file $file: $_" };
        }
    }

}

sub prepare_app {
    my $self = shift;
    return if $self->{app}; # TODO: re-read ontologies if changed

    my $ns = RDF::NS->new('any');
    $self->{namespaces} = $ns;

    $self->load_ontologies;

    # TODO: customize template directory

    my ($templates, $static) = map {
        try { dist_dir('RDF-JAOS',$_) } || catfile('share',$_);
    } qw(templates static);

    $self->{app} = builder {

        enable 'Static',
            path => qr{\.(png|js|css)$},
            root => $static;

        enable 'Negotiate',
            formats => {
                html  => { type => 'text/html' },
                xhtml => { type => 'application/xhtml+xml' },
                rdf   => { type => 'application/rdf+xml' },
                ttl   => { type => 'text/turtle' },
                _     => { charset => 'utf-8' },
            },
            extension => 'strip',   # .rdf .ttl ...
            parameter => 'format';  # ?format=rdf
            
        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                my $path = $req->path_info;
                my $format = $env->{'negotiate.format'} // '';

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

                    # serve ontology as file
                    if ( $format eq 'ttl' and $ont ) {
                        log_info { $ont->{file} };
                        if ($ont->{file} =~ /\.ttl/) {
                            my $file = Plack::App::File->new( file => $ont->{file} );
                            return $file->($env);
                        } else {
                            require RDF::Trine::Serializer;
                            return [200,['Content-Type'=>'text/turtle'],[ $ont->graph->ttl ] ];
                        }
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
