[%# 
    Useful macros
%]

[% MACRO link(uri) BLOCK -%]
[% islocal = uri.revs.size > 0 %]
  <a href="[% IF islocal -%]
    #[% uri.qname -%]
    [%- ELSE -%][% uri -%]
  [%- END %]" title="[% uri %]">[% uri.qname %]</a>
[%- END %]

[% MACRO linklist(uris) FOREACH uri IN uris -%]
  [%- IF loop.prev %], [% END -%]
  [%- link(uri) -%]
[%- END %]

[% MACRO element(e) BLOCK -%]
<h4 id="[% e.qname %]">[% e.qname %]</h4>
<p class="uriline">
    <a class="uri" href="[% e %]">[% e %]</a>
    [%- qname = e.qname.split(':') -%]
    [%- prefix = qname.first -%]
    [%- IF prefix != ontology.prefix AND ontologies.$prefix %]
      <a href="[% prefix %]#[% prefix %]:[% qname.last %]" class="small">more</a>
    [% END -%]
</p>
[%- IF e.rdfs_comment OR e.rdfs_label %]
<p>[% IF e.rdfs_label %]<b>[% e.rdfs_label %]:</b> [% END -%] 
   [%- e.rdfs_comment | html %]</p>
[% END -%]
  [%# e.ttlpre %]
[% END %]


