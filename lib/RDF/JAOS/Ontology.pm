package RDF::JAOS::Ontology;
#ABSTRACT: Information about an RDF ontology

use 5.10.0;
use RDF::Trine;
use Try::Tiny;

sub new {
    my ($class, $source) = @_;

    my $model = RDF::Trine::Model->new;

    my $self = bless {
        source => $source,
        model  => $model,
    }, $class;

    if ($source =~ /^https?:/) {
        RDF::Trine::Parser->parse_url_into_model( $source, $model );
    } else {
        $self->{file} = $source;
        my $parser = RDF::Trine::Parser->guess_parser_by_filename( $source );
        $parser->parse_file_into_model( "file://$source", $source, $model );
    }
    
    $self;
}

1;
