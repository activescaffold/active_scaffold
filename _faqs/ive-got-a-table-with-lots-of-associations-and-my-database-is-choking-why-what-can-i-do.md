---
title: "I’ve got a table with lots of associations, and my database is choking. Why?"
date: "2025-02-17 14:36:09.000000000 +01:00"
---

ActiveScaffold attempts to utilize eager loading when displaying the list, under the assumption that every association column will need to display something about the associated records. If this is too much, you have two options:

1.  Remove some association columns from the list (e.g. `config.list.columns.exclude :association_column`)
2.  Disable the eager loading for some association columns by setting `config.columns[:association_column].includes = nil`
