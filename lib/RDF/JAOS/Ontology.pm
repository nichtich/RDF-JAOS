package RDF::JAOS::Ontology;
#ABSTRACT: Information about an RDF ontology
use strict;
use warnings;
use 5.10.1;

use Carp;
use RDF::Trine;
use Try::Tiny;
use RDF::NS;
use RDF::Lazy qw(0.7);

=head1 SYNOPSIS

    $ont = RDF::JAOS::Ontology->new( 
        from       => 'example.ttl',
        prefix     => 'foo'
        base       => 'http://example.org/',
        namespaces => {
            rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
            owl => 'http://www.w3.org/2002/07/owl#',
            dct => 'http://purl.org/dc/terms/',
        }
    );

    $ont->prefix;        # the ontology's prefix
    $ont->graph;         # the ontology as RDF::Lazy graph

    $ont->me->dc_title;  # get the ontology's title 
    
    $ont->graph->subjects('rdf:type','owl:Class'); # get all classes

=head1 DESCRIPTION

RDF::JAOS::Ontology contains an RDF ontology, wrapped as L<RDF::Lazy>
object for easy access.

=method new( from => $file, prefix => $prefix, base => $uri ... )

Creates a new RDF::JAOS::Ontology object C<from> a given file with some given
C<prefix> and C<base> URI. A namespace mapping can be added as hash, instance
of L<RDF::NS> or date that is passed to the constructor of L<RDF:NS>.

The following additional properties are set:

=over 4

=item source

The source which the ontology was read from (probably an URL or filename).

=item file

The source file, if the ontology was read from a file.

=back

The constructor may croak on failure.

=cut

sub new {
    my ($class, %args) = @_;

    my $from = $args{from};
    my $ns   = $args{namespaces};
       $ns ||= (ref $ns ? RDF::NS->new($ns) : { });

    my $self = bless {
        source => $from,
        base   => $args{base},
    }, $class;

    my $model = RDF::Trine::Model->new;

    try {
        if ($from =~ /^https?:/) {
            RDF::Trine::Parser->parse_url_into_model( $from, $model );
            $self->{base} //= $from;
        } else {
            $self->{file} = $from;
            $self->{base} //= "file://$from";
            my $parser = RDF::Trine::Parser->guess_parser_by_filename( $from );
            $parser->parse_file_into_model( $self->{base}, $from, $model );
        }
    } catch {
        croak "failed to read ontology from $from: $_";
    };

    $self->{graph} = RDF::Lazy->new( rdf => $model, namespaces => $ns );
    $self->prefix( $args{prefix} );

    $self;
}

=method base

Returns the ontology's base URI as string.

=cut

sub base {
    shift->{base}
}

=method1 me

Returns the ontology's base URI as L<RDF::Lazy::Resource>.

=cut

sub me {
    my $self = shift;
    $self->graph->resource( $self->{base} );
}

=method1 graph

Returns the ontology's RDF graph as L<RDF::Lazy>.

=cut

sub graph {
    shift->{graph};
}

=method prefix( [ $prefix ] )

Gets and/or sets the ontology's prefix. Setting a new prefix will add another
prefix to namespace mapping to the RDF::Lazy's namespace map.

=cut

sub prefix {
    my $self = shift;
    if (@_) {
        my $prefix = shift;
        croak "invalid ontology prefix: $prefix"
            unless $prefix =~ /^[a-z][a-z0-9]+$/;
        $self->{prefix} = $prefix;
        $self->graph->namespaces->{ $prefix } = $self->base;
    }
    $self->{prefix};
}

1;
