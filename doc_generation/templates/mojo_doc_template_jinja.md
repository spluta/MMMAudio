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
{% if not loop.last %}
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>
{% endif %}
{% endfor %}
{% endif %}

<!-- FUNCTIONS -->
{% if decl.functions %}

<hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

# **Functions not tied to Structs:**

{% for function in decl.functions %}
{% include 'function.md' %}
{% if not loop.last %}
<hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">
{% endif %}
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