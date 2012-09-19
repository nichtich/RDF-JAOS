[% 
my = []; yours = [];
FOREACH e IN resources;
    IF e.qname.split(':').first == ontology.prefix; 
        my.push(e);
    ELSE; 
        yours.push(e); 
    END;
END;
%]
