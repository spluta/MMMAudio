### {{ function.name }}

{% for overload in function.overloads %}
{% if overload.summary %}
{{ overload.summary }}
{% endif %}

{% if overload.description %}
{{ overload.description }}
{% endif %}

## Signature

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
## Parameters

{% for param in overload.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.args %}
## Arguments

{% for arg in overload.args %}
- **{{ arg.name }}**{% if arg.type %}: `{{ arg.type }}`{% endif %}{% if arg.default %} = `{{ arg.default }}`{% endif %}{% if arg.description %} - {{ arg.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.returns %}
## Returns

{% if overload.returns.type %}**Type**: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %}
{% endif %}

{% if overload.hasDefaultImplementation %}
!!! info "Default Implementation"
    This method has a default implementation.
{% endif %}

---

{% endfor %}
