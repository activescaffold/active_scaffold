---
title: "How do I set configuration options globally so that they affect all controllers?"
date: "2025-02-17 14:38:17.000000000 +01:00"
---

Configuration options that you wish to set globally for all controllers (as long as that option is marked as *global* in the ActiveScaffold API documentation) must be placed in an initializer file. The format for setting global configuration options is:

```ruby
ActiveScaffold.defaults do |config|
  config.   #fill in configuration option here
end
```
