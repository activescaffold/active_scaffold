---
title: "API"
category: "API Reference"
---

## Introduction: Configuration Organization

ActiveScaffold is both configurable and customizable. What's the difference? Configuring ActiveScaffold means throwing flags and setting options and manipulating the setup; this happens in your controller. Customizing ActiveScaffold means defining conventional methods or template overrides that it will intelligently use when available. We've tried to strike a balance between configuration and customization that is intuitive and maintainable.

The flexible configuration system happens in a cascade-like manner. You may configure ActiveScaffold generally for your entire application or for a specific controller. At each of those levels, global and local, you may configure either core settings or action-specific settings. Now, not all settings exist at both the global and core levels, or exist both in the core settings and the action-specific settings. They simply exist and inherit wherever they are meaningful. This cascade system is nice to be aware of, but for the most part it should be invisible and you should be able to configure things _where they make sense_.
 
The customization can also happen on global and local levels. ActiveScaffold globally respects conventional methods on your models and template overrides in a special directory (more on that later). But it also locally respects conventional methods in your controllers or helpers, and uses template overrides in your controller's views directory.

## Configuration (Settings)

- [API: Core](/doc/api-core/)
- [API: List](/doc/api-list/)
- [API: Create](/doc/api-create/)
- [API: Update](/doc/api-update/)
- [API: Delete](/doc/api-delete/)
- [API: Show](/doc/api-show/)
- [API: Search](/doc/api-search/)
- [API: FieldSearch](/doc/api-fieldsearch/)
- [API: Nested](/doc/api-nested/)
- [API: Subform](/doc/api-subform/)
- [API: Mark](/doc/api-mark/)
- [API: Action Link](/doc/api-action-link/)
- [API: Column](/doc/api-column/)
- [API: Action Columns](/doc/api-action-columns/)
- [Describing Records: to_label](/doc/describing-records-to_label/)
- [RESTful Scaffolding](/doc/restful-scaffolding/)
- [JS Config](/doc/js-config/)

### Deprecated

- [API: LiveSearch](/doc/api-livesearch/)

## View Customization (Overrides)

- [Column Overrides (List)](/doc/column-overrides-list/)
- [Form Overrides](/doc/form-overrides/)
- [Show Overrides](/doc/show-overrides/)
- [Subform Layout Overrides](/doc/subform-layout-overrides/)
- [Subform Overrides](/doc/subform-overrides/)
- [Search Overrides](/doc/search-overrides/)
- [Template Overrides](/doc/template-overrides/)