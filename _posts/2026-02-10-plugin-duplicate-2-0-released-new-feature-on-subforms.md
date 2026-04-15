---
title: "Plugin Duplicate 2.0 Released: new feature on subforms"
date: "2026-02-10 11:47:10.000000000 +01:00"
categories:
- Releases
---

**ActiveScaffoldDuplicate 2.0** has been released, featuring a new feature, requiring ActiveScaffold 4.2.

Built on the new helper `active_scaffold_subform_record_actions` introduced in ActiveScaffold 4.2, adds support to have a duplicate button on the subform rows, next to the remove button. It will send a request to the action `edit_associated`, with the fields of the row and a `dup` parameter. Then, a new row will be added, copying the values from the duplicated row.
