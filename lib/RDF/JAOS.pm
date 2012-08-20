package RDF::JAOS;
#ABSTRACT: Just another Ontology server

use 5.10.0;
use File::ShareDir qw(module_dir);
use Dancer ':syntax';

=head1 DESCRIPTION

JAOS is a simple web application to serve RDF ontologies in OWL and/or RDFS.
It's primary purpose is providing both, a machine-readable version and a nice
browsable interface. 

=cut

set 'log'      => 'debug';
set 'layout'   => 'main';

any '/' => sub {
    template 'index.tt';
};

