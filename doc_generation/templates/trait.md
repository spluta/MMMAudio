### {{ trait.name }}

{% if trait.summary %}
{{ trait.summary }}
{% endif %}

{% if trait.description %}
{{ trait.description }}
{% endif %}

{% if trait.parameters %}
## Parameters

{% for param in trait.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if trait.functions %}
{% set displayed_functions = trait.functions
    | rejectattr('name', 'equalto', '__copy__')
    | rejectattr('name', 'equalto', '__copyinit__')
    | rejectattr('name', 'equalto', '__moveinit__')
%}
{% if displayed_functions %}
## Required Methods

{% for function in displayed_functions %}
{% include 'trait_method.md' %}
{% endfor %}
{% endif %}
{% endif %}

{% if trait.constraints %}
## Constraints

{{ trait.constraints }}
{% endif %}

{% if trait.deprecated %}
!!! warning "Deprecated"
    {{ trait.deprecated }}
{% endif %}