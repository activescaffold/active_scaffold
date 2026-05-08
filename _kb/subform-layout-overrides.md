---
title: "Subform Layout Overrides"
category: "Customization"
---

If you want to override a subform template for a controller, and use this template in all views which include a subform of that controller, you must put a `_#{subform_layout}_subform.html.erb` partial in `app/views/<controller>/` directory (e.g. `app/views/comments/` for the CommentsController and it will be used instead of the layout which comes with ActiveScaffold in all controllers with include a subform of CommentsController).

You can look at `_horizontal_subform.html.erb` or `_vertical_subform.html.erb` in `app/views/active_scaffold_overrides/` directory of ActiveScaffold for an example of subform partials. Don't forget use the scope parameter to name your fields or the model in subform won't be created/updated.
