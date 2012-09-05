use strict;
use warnings;
use v5.10;
use Test::More;
use File::Slurp;

use RDF::JAOS::Ontology;

my $prefix = 'foo';
my $base   = 'http://example.org/';

my $ont = RDF::JAOS::Ontology->new(
    prefix     => $prefix,
    base       => $base,
    from       => 't/example.ttl',
    namespaces => { 
        rdf => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
        owl => 'http://www.w3.org/2002/07/owl#',
        dct => 'http://purl.org/dc/terms/',
    },
);

isa_ok $ont, 'RDF::JAOS::Ontology';
is $ont->prefix, $prefix, 'prefix';
is $ont->base, $base, 'base';

is $ont->me->dct_title->str, 'example ontology', 'lazy access';

my @classes = sort map { "$_" } $ont->graph->subjects('rdf:type','owl:Class');
is_deeply \@classes, [qw(http://example.org/Bar http://example.org/Foo)], 'classes';

done_testing;
