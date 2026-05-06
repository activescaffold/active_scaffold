---
title: "Rows from some subforms never are saved. Why?"
date: "2025-02-17 14:38:29.000000000 +01:00"
---

When blank rows are shown automatically in subforms (without clicking in add new), ActiveScaffold check if some field in row has a non-default value, and date and boolean fields are ignored in this check. So neither rows with all fields with default value are saved, neither rows which all fields are dates or booleans are saved.

When you turn off blank rows, this check is skipped, so all rows added are saved, even blank rows.
