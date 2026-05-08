---
title: "Default values"
category: "Advanced"
---

# How to set default values to new records

Active Scaffold use default values in new records the same way any active record model does, that is, using defaults defined in database. However, sometimes you need something more flexible than altering database or add some logic to it. 

There are 2 ways of setting initial values for records: the Active Scaffold way and the Rails way. Each one has different benefits:

* Rails way: For general purpose. If you'll use it with or without AS. Model way.
* AS way: Let's you reuse AS features like active_scaffold_config, params, etc. Controller way. 

## Rails way

By following advice from [Jeff Perrin at stackoverflow](http://stackoverflow.com/questions/328525/what-is-the-best-way-to-set-default-values-in-activerecord), you may use after_initialize from active record: 

{% highlight ruby -%}
    class Person
        has_one :address
        after_initialize :init
    
        def init
          self.number  ||= 0.0           #will set the default value only if it's nil
          self.address ||= build_address #let's you set a default association
        end
    end 
{%- endhighlight %}
**CAREFUL** with the method above: AS uses Model.new in many ways, to draw how an object looks, to auto-configure list views, for example. So, if you have complex processing here, or using live data to build the object, choose the AS way below. 


## AS way

If you need to use some request parameters or session info, or if you don't want to add after_initialize callback, you can override do_new method in the controller:

{% highlight ruby -%}
    class PeopleController < ApplicationController
        protected
        def do_new
            super
            @record.owner = current_user
        end
     end
{%- endhighlight %}
