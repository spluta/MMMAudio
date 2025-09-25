
---

# `fn` {{ function.name }}

{% for overload in function.overloads %}
{% if overload.summary %}
{{ overload.summary }}
{% endif %} <!-- endif overload.summary -->

{% if overload.description %}
{{ overload.description }}
{% endif %} <!-- end if overload.description -->

## Signature

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
## Parameters

{% for param in overload.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %} <!-- end for param in overload.parameters -->
{% endif %} <!-- endif overload.parameters -->

{% if overload.args %}
## Arguments

{% for arg in overload.args %}
- **{{ arg.name }}**{% if arg.type %}: `{{ arg.type }}`{% endif %}{% if arg.default %} = `{{ arg.default }}`{% endif %}{% if arg.description %} - {{ arg.description }}{% endif %}
{% endfor %} <!--end for arg in overload.args -->
{% endif %} <!-- endif overload.args -->

{% if overload.returns %}
## Returns

{% if overload.returns.type %}**Type**: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %}
{% endif %} <!-- endif overload.returns -->

{% if overload.raises %}
## Raises

{% if overload.raisesDoc %}
{{ overload.raisesDoc }}
{% endif %}
{% endif %} <!-- endif overload.raises -->

{% if overload.constraints %}
## Constraints

{{ overload.constraints }}
{% endif %} <!-- endif overload.constraints -->

{% if overload.deprecated %}
!!! warning "Deprecated"
    {{ overload.deprecated }}
{% endif %}

{% endfor %} <!-- endfor overload in function.overloads -->
