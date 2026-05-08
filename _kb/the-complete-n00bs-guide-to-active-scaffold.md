---
title: "The Complete N00b's Guide to Active Scaffold"
category: "Getting Started"
---

If you’re new to both Rails and Active Scaffold, some things which may seem obvious to more experienced hands, can be frustratingly perplexing. 

Rails is neat, but it can also be confusing for a C or Java programmer, Rails just takes care of some things that you’d otherwise be doing by hand; this can be perplexing.  because you’re looking for where things are _happening_ in the code to get practical examples, and none exist. 

_So what do you do?_ 

You just try stuff and hope it works and when it doesn’t you pull your hair out.
 This guide helps to overcome some of those issues. We’ll be adding to this guide as we discover little solutions to mind-blowing (for n00bs) anyway problems.

**How to Make Active Scaffold work with  _Acts as [whatever]_**

The “Acts As” plug ins are awesome, ActiveScaffold is awesome. Getting them to work together, _not so awesome_.  You can view your scaffolds but when you try to create, you get the dreaded _500 error_ -- that had me stumped for a week.  Here’s the long and short of it, you need to tell Active Scaffold what fields you’re bringing in from the Acts_As polymorphic association (because it doesn't know otherwise). You do that like this:

{% highlight ruby -%}
# I have Acts_as_Taggable_on installed in my story module, I have created scopes
# for :destinations and :interests, if I don’t tell Active Scaffold that,
# it has a friggin stroke when we try to create records. 

active_scaffold :story do |config|
    config.columns = [:title, :by_line, :one_liner, :lede,
      :body, :custom_layout, :layout,
      :editorial_workflow_status, :content_type, :publish_date, :destinations,
      :interests]
end
{%- endhighlight %}

Now, **poof** it works!

---


**How to make a look up field without using a table**
So this has been killing me for a week. The scenario is simple. I have a table “Stories”, which has a field “Content Type”.  You know for ‘Reviews’, ‘Blogs’, or whatever. Now the easy thing to do would be to create a look up table, and active scaffold would do it’s magic behind the scenes, and we’d be good to go. 

_except_

Look up tables whose sole purpose is to look up a single string would create a choke point at the database layer for a high performance application.  So I use integers, and symbols, and all is good, _right_?

_yeah, not so much_.


You read in the net that the following should work: 

{% highlight ruby -%}
active_scaffold :story do |config|
    #do stuff like specify what fields we want so that Acts_on_[whatever] doesn’t die
      config.columns[:content_type].form_ui = :select
      config.columns[:content_type].options = {"story" => 1, 
                             "review" => 2, "story page" => 3}
end
{%- endhighlight %}

Of course that doesn’t work, becuase it's an old way which was deprecated and removed support later. This works:

{% highlight ruby -%}
active_scaffold :story do |config|
     #do stuff like specify what fields we want so that 
     #Acts_on_[whatever] doesn’t break on create

     config.columns[:content_type].form_ui = :select
     config.columns[:content_type].options[:options] = [["story",  1], ["story", 2]]
end
{%- endhighlight %}

To combine it with localization and validation in a DRY way look at [Enum columns](/doc/enum-columns/)

