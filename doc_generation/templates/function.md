
---

{% for overload in function.overloads %}

# `fn` {{ function.name }}

<div style="margin-left:3em;" markdown="1">

{% if overload.summary %}
{{ overload.summary }}
{% endif %} <!-- endif overload.summary -->

{% if overload.description %}
{{ overload.description }}
{% endif %} <!-- end if overload.description -->

**Signature**

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
**Parameters**

| Name | Type | Description |
|------|------|-------------|
{% for param in overload.parameters -%}
| **{{ param.name }}** | {% if param.type %}`{{ param.type }}`{% else %}—{% endif %} | {% if param.description %}{{ param.description }}{% else %}—{% endif %} |
{% endfor -%} <!-- end for param in overload.parameters -->
{% endif %} <!-- endif overload.parameters -->

{% if overload.args %}
**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
{% for arg in overload.args -%}
| **{{ arg.name }}** | {% if arg.type %}`{{ arg.type }}`{% else %}—{% endif %} | {% if arg.default %}`{{ arg.default }}`{% else %}—{% endif %} | {% if arg.description %}{{ arg.description }}{% else %}—{% endif %} |
{% endfor -%} <!--end for arg in overload.args -->
{% endif %} <!-- endif overload.args -->

{% if overload.returns %}
**Returns**

{% if overload.returns.type %}**Type**: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %}
{% endif %} <!-- endif overload.returns -->

{% if overload.raises %}
**Raises**

{% if overload.raisesDoc %}
{{ overload.raisesDoc }}
{% endif %}
{% endif %} <!-- endif overload.raises -->

{% if overload.constraints %}
**Constraints**

{{ overload.constraints }}
{% endif %} <!-- endif overload.constraints -->

{% if overload.deprecated %}
!!! warning "Deprecated"
    {{ overload.deprecated }}
{% endif %}

</div>

{% endfor %} <!-- endfor overload in function.overloads -->
