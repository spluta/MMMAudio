### {{ trait.name }}

{% if trait.summary %}
{{ trait.summary }}
{% endif %}

{% if trait.description %}
{{ trait.description }}
{% endif %}

## Signature

```mojo
{{ trait.signature }}
```

{% if trait.parameters %}
## Parameters

{% for param in trait.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if trait.functions %}
## Required Methods

{% for function in trait.functions %}
{% include 'trait_method.md' %}
{% endfor %}
{% endif %}

{% if trait.constraints %}
## Constraints

{{ trait.constraints }}
{% endif %}

{% if trait.deprecated %}
!!! warning "Deprecated"
    {{ trait.deprecated }}
{% endif %}

---
