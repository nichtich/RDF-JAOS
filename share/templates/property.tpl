[% element(property) %]
[% status   = property.vs_term_status %]
[% super    = property.rdfs_subPropertyOf_ %]
[% domain   = property.rdfs_domain_ %]
[% range    = property.rdfs_range_ %]
[% inverse  = property.owl_inverseOf %]
[% disjoint = property.owl_disjointWith_ %]
[% seealso  = property.rdfs_seeAlso_ %]
[% note     = property.skos_scopeNote %]
<div>
  <dl class="table-display">
    [% IF status %]
      <dt>Status</dt>
      <dd class="status-[% status %]">[% status %]</dd>
    [% END %]
    [% IF super.size %]
      <dt>⊆ super</dt>
      <dd>[% linklist(super) %]
          (which is implied by having a [% property.qname %])</dd>
    [% END %]
    [% IF domain %]
      <dt>↦ domain</dt>
      <dd>[% linklist(domain) %]
          (which being a is implied by having a [% property.qname %])</dd>
    [% END %]
    [% IF range %]
      <dt>⇥ range</dt>
      <dd>[% linklist(range) %]
          (which every value of [% property.qname %] is)</dd>
    [% END %]
    [% IF inverse %]
      <dt>⇄ inverse property</dt>
      <dd>[% linklist(inverse) %]</dd>
    [% END %]
    [% IF disjoint.size %]
      <dt>≠ Disjoint</dt>
      <dd>[% linklist(disjoint) %]
          (which nothing can have together with [% class.qname %])</dd>
      </dd>
    [% END %]
    [% IF note %]
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
