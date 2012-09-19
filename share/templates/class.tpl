[% element(class) %]
[% status   = class.vs_term_status %]
[% sub      = class.revs('rdfs:subClassOf') %]
[% super    = class.rdfs_subClassOf_ %]
[% disjoint = class.owl_disjointWith_ %]
[% equiv    = class.owl_equivalentClass_ %]
[% seealso  = class.rdfs_seeAlso_ %]
[% notes    = class.skos_scopeNote_ %]
<div>
  <dl class="table-display">
    [% IF status %]
      <dt>Status</dt>
      <dd class="status status-[% status %]">[% status %]</dd>
    [% END %]
    [% IF equiv.size %]
       <dt>≡ Equivalent[% IF equiv.size > 1 %]es[% END %]</dt>
       <dd>[% linklist(equiv) %]
           (which all [% class.qname %] also are, and vice versa)</dd>
    [% END %]
    [% IF super.size %]
      <dt>⊆ Superclass[% IF super.size > 1 %]es[% END %]</dt>
      <dd>[% linklist(super) %]
          (which all [% class.qname %] also are)</dd> 
    [% END %]
    [% IF sub.size %]
      <dt>⊇ Subclass[% IF sub.size > 1 %]es[% END %]</dt>
      <dd>[% linklist(sub) %]
          (which all [% class.qname %] might also be)</dd>
    [% END %]
    [% IF disjoint.size %]
      <dt>≠ Disjoint</dt>
      <dd>[% linklist(disjoint) %]
          (which no [% class.qname %] is)</dd>
      </dd>
    [% END %]
    [% FOREACH note IN notes %]
      <dt class="note">note</dt>
      <dd class="note">[% note | html %]</dd>
    [% END %]
    [% IF seealso.size %]
      <dt class="note">see also</dt>
      <dd class="note">[% linklist(seealso) %]</dd>
    [% END %]
  </dl>
  <div class='cleaner'>&nbsp;</div>
</div>
