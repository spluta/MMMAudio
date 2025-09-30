{% if decl.summary %}
{{ decl.summary }}
{% endif %}

{% if decl.description %}
{{ decl.description }}
{% endif %}

<!-- STRUCTS -->
{% if decl.structs %}
{% for struct in decl.structs %}

{% include 'struct.md' %}

{% endfor %}
{% endif %}

<!-- FUNCTIONS -->
{% if decl.functions %}
# Functions

{% for function in decl.functions %}
{% include 'function.md' %}
{% endfor %} <!-- endfor function in decl.functions -->
{% endif %} <!-- endif  decl.functions -->

<!-- TRAITS -->
{% if decl.traits %}
# Traits

{% for trait in decl.traits %}
{% include 'trait.md' %}
{% endfor %}
{% endif %}

{% if version %}
---

*Documentation generated with `mojo doc` from Mojo version {{ version }}*
{% endif %}