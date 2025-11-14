{% if decl.summary %}
{{ decl.summary }}
{% endif %}

{% if decl.description %}
{{ decl.description }}
{% endif %}

<!-- TRAITS -->
{% if decl.traits %}

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #9333EA; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Traits
</div>

{% for trait in decl.traits %}
{% include 'trait.md' %}
{% endfor %}
{% endif %}

<!-- STRUCTS -->
{% if decl.structs %}

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>

{% for struct in decl.structs %}

{% include 'struct.md' %}
{% if not loop.last %}
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>
{% endif %}
{% endfor %}
{% endif %}

<!-- FUNCTIONS -->
{% if decl.functions %}

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)

{% for function in decl.functions %}
{% include 'function.md' %}
{% if not loop.last %}
<hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">
{% endif %}
{% endfor %} <!-- endfor function in decl.functions -->
{% endif %} <!-- endif  decl.functions -->

{% if version %}
---

*Documentation generated with `mojo doc` from Mojo version {{ version }}*
{% endif %}