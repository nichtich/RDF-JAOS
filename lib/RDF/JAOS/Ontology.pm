package RDF::JAOS::Ontology;
#ABSTRACT: Information about an RDF ontology

use 5.10.0;
use RDF::Trine;
use Try::Tiny;
use RDF::NS;
use RDF::Lazy qw(0.7);

=head1 SYNOPSIS

    $ont = RDF::JAOS::Ontology->new( 
       'example.ttl',                  # file that contains the ontology
        foo => 'http://example.org/',  # prefix and namespace
        { dc => 'http://purl.org/dc/elements/1.1/' } # more namespaces
    );

    $ont->{prefix};      # foo
    $ont->{graph};       # the ontology as RDF::Lazy graph

    $ont->graph
    $ont->me->dc_title;  # get the ontology's title 

=head1 DESCRIPTION

This class wraps a L<RDF::Trine::Model>, that contains an RDF ontology,
as L<RDF::Lazy> object, enriched with the following properties:

=over 4

=item graph

The L<RDF::Lazy> object (also provided as method of same name).

=item source

The source which the ontology was read from (probably an URL or filename).

=item file

The source file, if the ontology was read from a file.

=item base

The ontology's base URI as string.

=item prefix

The preferred namespace prefix.

=back

=method new( $source, $prefix => $base [, $namespaces ] )

Retrieves a new ontology object from a source, using a given prefix, and base
URI. The optional namespace argument can be a (possibly blessed) hash
reference, for instance an L<RDF::NS> object. The namespace hash is is modified
to include a mapping from the ontology's prefix to its base URI.

=cut

sub new {
    my ($class, $source, $prefix, $base, $namespaces) = @_;

    my $model = RDF::Trine::Model->new;

    my $self = bless {
        source => $source,
        prefix => $prefix,
    }, $class;

    if ($source =~ /^https?:/) {
        RDF::Trine::Parser->parse_url_into_model( $source, $model );
        $self->{base} = $base // $source;
    } else {
        $self->{file} = $source;
        $self->{base} = $base // "file://$source";
        my $parser = RDF::Trine::Parser->guess_parser_by_filename( $source );
        $parser->parse_file_into_model( $self->{base}, $source, $model );
    }

    if ($namespaces) {
        $namespaces = RDF::NS->new( $namespaces ) unless ref $namespaces;
        $namespaces->{$prefix} = $base;
    } else {
        $namespaces = { $prefix => $base };
    }

    $self->{graph} = RDF::Lazy->new( rdf => $model, namespaces => $namespaces );
    $self;
}

=method1 me

Returns the ontology's base URI as L<RDF::Lazy::Resource> object.

=cut

sub me {
    my $self = shift;
    $self->{graph}->resource( $self->{base} );
}

=method1 graph

Returns the ontology's RDF graph as L<RDF::Lazy> object.

=cut

sub me {
    my $self = shift;
    $self->{graph}->resource( $self->{base} );
}

1;
