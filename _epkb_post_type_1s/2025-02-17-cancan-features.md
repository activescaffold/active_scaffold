---
title: CanCan Features
date: "2025-02-17 13:59:14.000000000 +01:00"
permalink: "/wiki-2/cancan-features/"
---

If you use [CanCan](https://github.com/ryanb/cancan) for authorization, the ActiveScaffold CanCan bridge auto-loads and plugs into ActiveScaffold by chaining your Ability rules in the default ActiveScaffold behavior. (Versions AS &gt;= 3.0.13 & CanCan ~&gt; 1.6.7)

**Disclaimer: Test your security setup! If your data is critical and you want complete peace of mind, you must test it yourself. Make sure you have been as specific as possible, and that you have tested to make sure your security methods are being used.**

### Features

[](https://github.com/activescaffold/active_scaffold/wiki/CanCan#features)

1.  activates only when CanCan is installed via default bridges `@install_if = lambda { Object.const_defined?(name) }` functionality
2.  delegates to [default AS security](https://github.com/activescaffold/active_scaffold/wiki/Security) in case CanCan says "no"
3.  integrates with `beginning_of_chain` both in "list" and "nested" via `CanCan#accessible_by`, feature more known as `load_and_authorize_resources`. This means that the index action will select from the database only allowed records for the current user, and the creation of a record is done on the allowed scope (ie.: `Model.where(restrictions_from_cancan).new`). Note that you must test this, because on some cases, when using MetaWhere or Squeel or scope-based conditions in CanCan rules, not all conditions can be used for creation.
