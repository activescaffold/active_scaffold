---
title: "I’m adding stuff to params[:record] but ActiveScaffold doesn’t use it. Why?"
date: "2025-02-17 14:37:55.000000000 +01:00"
---

ActiveScaffold doesn’t just apply the whole `params[:record]` hash. Instead, **it whitelists fields it expects from the form**. Which is to say, if ActiveScaffold didn’t know that role\_id was supposed to be on the form, it will ignore the params\[:record\]\[:role\_id\] entry. If it didn’t work this way, then URL hackers could submit extra data and do all kinds of fun things including privilege escalation.

If you need to apply your own data to the record before its gets saved, what you should do instead is define `before_create_save(record)` or `before_update_save(record)` on your controller. ActiveScaffold will check for these methods and pass them the record object so you can do common things like attach the current user as the record’s owner.
