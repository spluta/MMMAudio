<!-- 
The content in this block from the mojo doc is referring to the document.
Since one document may contain many functions and/or structs, we won't

# {{ decl.name }}

{% if decl.summary %}
{{ decl.summary }}
{% endif %}

{% if decl.description %}
{{ decl.description }}
{% endif %} -->

{% if decl.functions %}
## Functions

{% for function in decl.functions %}
### {{ function.name }}

{% for overload in function.overloads %}
{% if overload.summary %}
{{ overload.summary }}
{% endif %}

{% if overload.description %}
{{ overload.description }}
{% endif %}

#### Signature

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
#### Parameters

{% for param in overload.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.args %}
#### Arguments

{% for arg in overload.args %}
- **{{ arg.name }}**{% if arg.type %}: `{{ arg.type }}`{% endif %}{% if arg.default %} = `{{ arg.default }}`{% endif %}{% if arg.description %} - {{ arg.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.returns %}
#### Returns

{% if overload.returns.type %}**Type**: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %}
{% endif %}

{% if overload.raises %}
#### Raises

{% if overload.raisesDoc %}
{{ overload.raisesDoc }}
{% endif %}
{% endif %}

{% if overload.constraints %}
#### Constraints

{{ overload.constraints }}
{% endif %}

{% if overload.deprecated %}
!!! warning "Deprecated"
    {{ overload.deprecated }}
{% endif %}

---

{% endfor %}
{% endfor %}
{% endif %}

{% if decl.structs %}
## Structs

{% for struct in decl.structs %}
### {{ struct.name }}

{% if struct.summary %}
{{ struct.summary }}
{% endif %}

{% if struct.description %}
{{ struct.description }}
{% endif %}

#### Signature

```mojo
{{ struct.signature }}
```

{% if struct.parentTraits %}
#### Parent Traits

{% for trait in struct.parentTraits %}
- [`{{ trait.name }}`]({{ trait.path }})
{% endfor %}
{% endif %}

{% if struct.parameters %}
#### Parameters

{% for param in struct.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if struct.fields %}
#### Fields

{% for field in struct.fields %}
- **{{ field.name }}**{% if field.type %}: `{{ field.type }}`{% endif %}{% if field.description %} - {{ field.description }}{% endif %}
{% endfor %}
{% endif %}

{% if struct.aliases %}
#### Aliases

{% for alias in struct.aliases %}
- **{{ alias.name }}**{% if alias.value %} = `{{ alias.value }}`{% endif %}{% if alias.description %} - {{ alias.description }}{% endif %}
{% endfor %}
{% endif %}

{% if struct.functions %}
#### Methods

{% for function in struct.functions %}
##### {{ function.name }}

{% for overload in function.overloads %}
{% if overload.summary %}
{{ overload.summary }}
{% endif %}

{% if overload.description %}
{{ overload.description }}
{% endif %}

###### Signature

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
###### Parameters

{% for param in overload.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.args %}
###### Arguments

{% for arg in overload.args %}
- **{{ arg.name }}**{% if arg.type %}: `{{ arg.type }}`{% endif %}{% if arg.default %} = `{{ arg.default }}`{% endif %}{% if arg.description %} - {{ arg.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.returns %}
###### Returns

{% if overload.returns.type %}**Type**: `{{ overload.returns.type }}`{% endif %}
{% if overload.returns.doc %}

{{ overload.returns.doc }}
{% endif %}
{% endif %}

{% if overload.raises %}
###### Raises

{% if overload.raisesDoc %}
{{ overload.raisesDoc }}
{% endif %}
{% endif %}

{% if overload.constraints %}
###### Constraints

{{ overload.constraints }}
{% endif %}

{% if overload.deprecated %}
!!! warning "Deprecated"
    {{ overload.deprecated }}
{% endif %}

{% if overload.isStatic %}
!!! info "Static Method"
    This is a static method.
{% endif %}

---

{% endfor %}
{% endfor %}
{% endif %}

{% if struct.constraints %}
#### Constraints

{{ struct.constraints }}
{% endif %}

{% if struct.deprecated %}
!!! warning "Deprecated"
    {{ struct.deprecated }}
{% endif %}

---

{% endfor %}
{% endif %}

{% if decl.traits %}
## Traits

{% for trait in decl.traits %}
### {{ trait.name }}

{% if trait.summary %}
{{ trait.summary }}
{% endif %}

{% if trait.description %}
{{ trait.description }}
{% endif %}

#### Signature

```mojo
{{ trait.signature }}
```

{% if trait.parameters %}
#### Parameters

{% for param in trait.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if trait.functions %}
#### Required Methods

{% for function in trait.functions %}
##### {{ function.name }}

{% for overload in function.overloads %}
{% if overload.summary %}
{{ overload.summary }}
{% endif %}

{% if overload.description %}
{{ overload.description }}
{% endif %}

###### Signature

```mojo
{{ overload.signature }}
```

{% if overload.parameters %}
###### Parameters

{% for param in overload.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.args %}
###### Arguments

{% for arg in overload.args %}
- **{{ arg.name }}**{% if arg.type %}: `{{ arg.type }}`{% endif %}{% if arg.default %} = `{{ arg.default }}`{% endif %}{% if arg.description %} - {{ arg.description }}{% endif %}
{% endfor %}
{% endif %}

{% if overload.returns %}
###### Returns

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
{% endfor %}
{% endif %}

{% if trait.constraints %}
#### Constraints

{{ trait.constraints }}
{% endif %}

{% if trait.deprecated %}
!!! warning "Deprecated"
    {{ trait.deprecated }}
{% endif %}

---

{% endfor %}
{% endif %}

{% if decl.aliases %}
## Aliases

{% for alias in decl.aliases %}
### {{ alias.name }}

{% if alias.summary %}
{{ alias.summary }}
{% endif %}

{% if alias.description %}
{{ alias.description }}
{% endif %}

#### Signature

```mojo
{{ alias.signature }}
```

{% if alias.value %}
#### Value

```mojo
{{ alias.value }}
```
{% endif %}

{% if alias.parameters %}
#### Parameters

{% for param in alias.parameters %}
- **{{ param.name }}**{% if param.type %}: `{{ param.type }}`{% endif %}{% if param.description %} - {{ param.description }}{% endif %}
{% endfor %}
{% endif %}

{% if alias.deprecated %}
!!! warning "Deprecated"
    {{ alias.deprecated }}
{% endif %}

---

{% endfor %}
{% endif %}

{% if version %}
---

*Generated from Mojo version {{ version }}*
{% endif %}