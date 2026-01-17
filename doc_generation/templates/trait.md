{% import '_badges.jinja' as badges %}
## trait {{ badges.trait_badge(trait.name) }}

{% if trait.summary %}
{{ trait.summary }}
{% endif %}

{% if trait.description %}
{{ trait.description }}
{% endif %}

{% if trait.guide %}
{{ trait.guide }}
{% endif %}

{% if trait.parameters %}
### {{ badges.trait_badge(trait.name) }} Parameters

{% for param in trait.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if trait.functions %}
### {{ badges.trait_badge(trait.name) }} Required Methods

{% for function in trait.functions %}
{% include 'trait_method.md' %}
{% endfor %}
{% endif %}

{% if trait.constraints %}
### {{ badges.trait_badge(trait.name) }} Constraints

{{ trait.constraints }}
{% endif %}

{% if trait.deprecated %}
!!! warning "Deprecated"
    {{ trait.deprecated }}
{% endif %}