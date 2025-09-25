
---

## {{ struct.name }}

<!-- SUMMARY -->
{% if struct.summary %}
**{{ struct.summary }}**
{% endif %}

<!-- DESCRIPTION -->
{% if struct.description %}
*{{ struct.description }}*
{% endif %}

<!-- PARENT TRAITS -->
{% if struct.parentTraits %}
*Parent Traits:* {% for trait in struct.parentTraits -%}`{{ trait.name }}`{% if not loop.last %}, {% endif %}{%- endfor %}
{% endif %}

<!-- PARAMETERS -->
{% if struct.parameters %}
**Parameters**

| Name | Type | Description |
|------|------|-------------|
{% for param in struct.parameters %}
| **{{ param.name }}** | {% if param.type %}`{{ param.type }}`{% else %}—{% endif %} | {% if param.description %}{{ param.description }}{% else %}—{% endif %} |
{% endfor %}
{% endif %}

<!-- FUNCTIONS -->
{% if struct.functions %}
**Functions**

{% for function in struct.functions %}
### **`{{ function.name }}`**

{% for overload in function.overloads %}
{% if overload.summary %}{{ overload.summary }}{% endif %}
{% if overload.description %}{{ overload.description }}{% endif %}

**Signature**
```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
**Parameters**
{% for param in overload.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}  
{% endfor %}
{% endif %}

{% if overload.args %}
**Arguments**
{% for arg in overload.args %}
- **{{ arg.name }}**{% if arg.type %}: `{{ arg.type }}`{% endif %}{% if arg.default %} = `{{ arg.default }}`{% endif %}{% if arg.description %} - {{ arg.description }}{% endif %}  
{% endfor %}
{% endif %}

{% if overload.returns %}
**Returns**
{% if overload.returns.type %}**Type**: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %}
{% endif %}

{% if overload.raises %}
## Raises
{% if overload.raisesDoc %}{{ overload.raisesDoc }}{% endif %}
{% endif %}

{% if overload.constraints %}
## Constraints
{{ overload.constraints }}
{% endif %}

{% if overload.deprecated %}
!!! warning "Deprecated"
    {{ overload.deprecated }}
{% endif %}

<!-- STATIC METHOD WARNING -->
{% if overload.isStatic %}
!!! info "Static Method"
    This is a static method.
{% endif %}

{% endfor %}
{% endfor %}
{% endif %}

{% if struct.constraints %}
## Constraints
{{ struct.constraints }}
{% endif %} <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
{% if struct.deprecated %}
!!! warning "Deprecated"
    {{ struct.deprecated }}
{% endif %}
