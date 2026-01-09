
{% import '_badges.jinja' as badges %}
# struct {{ badges.struct_badge(struct.name) }}
{% if struct.summary %}
**{{ struct.summary }}**
{% endif %}

<!-- DESCRIPTION -->
{% if struct.description %}
{{ struct.description }}
{% endif %}

{% if struct.guide %}
{{ struct.guide }}
{% endif %}

<!-- PARENT TRAITS -->
{% if struct.parentTraits %}
*Traits:* {% for trait in struct.parentTraits -%}`{{ trait.name }}`{% if not loop.last %}, {% endif %}{%- endfor %}
{% endif %}

<!-- PARAMETERS -->
{% if struct.parameters %}
{{ badges.struct_badge(struct.name) }} **Parameters**

| Name | Type | Description |
|------|------|-------------|
{% for param in struct.parameters %}
| **{{ param.name }}** | {% if param.type %}`{{ param.type }}`{% else %}—{% endif %} | {% if param.description %}{{ param.description }}{% else %}—{% endif %} |
{% endfor %}
{% endif %}

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
{% if struct.functions %}
## {{ badges.struct_badge(struct.name) }} **Functions**

{% for function in struct.functions %}

{% for overload in function.overloads %}

### `struct` {{ badges.struct_badge(struct.name) }} . `fn` {{ badges.fn_badge(function.name) }}

<div style="margin-left:3em;" markdown="1">

{% if overload.summary %}{{ overload.summary }}{% endif %}

{% if overload.description %}{{ overload.description }}{% endif %}

`fn` {{ badges.fn_badge(function.name) }} **Signature**  

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
`fn` {{ badges.fn_badge(function.name) }} **Parameters**

| Name | Type | Description |
|------|------|-------------|
{% for param in overload.parameters %}
| **{{ param.name }}** | {% if param.type %}`{{ param.type }}`{% else %}—{% endif %} | {% if param.description %}{{ param.description }}{% else %}—{% endif %} |
{% endfor %}
{% endif %}

{% if overload.args %}
`fn` {{ badges.fn_badge(function.name) }} **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
{% for arg in overload.args %}
| **{{ arg.name }}** | {% if arg.type %}`{{ arg.type }}`{% else %}—{% endif %} | {% if arg.default %}`{{ arg.default }}`{% else %}—{% endif %} | {% if arg.description %}{{ arg.description }}{% else %}—{% endif %} |
{% endfor %}
{% endif %}

{% if overload.returns %}
`fn` {{ badges.fn_badge(function.name) }} **Returns**
{% if overload.returns.type %}: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %} 
{% endif %}

{% if overload.raises %}
**Raises**
{% if overload.raisesDoc %}{{ overload.raisesDoc }}{% endif %}
{% endif %}

{% if overload.constraints %}
**Constraints**
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

</div>

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
