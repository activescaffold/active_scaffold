---
title: "How to Approach Active Scaffold Use Cases and Benefits"
category: "Getting Started"
---

Ok, so there’s this plugin called ActiveScaffold, right? And you’ve installed it, and it looks cool, but you’re trying to figure out where to use it and how it can benefit you, and you’re wondering where to start reading in the documentation. Well look no further – this is our attempt to help provide some perspective.

## Use Cases

The word “scaffold” has something of a bad rep in the Rails community. On the one hand, you’ve got people telling you that scaffolds are just to “get you started” and that they should be replaced by something custom as soon as you have time. But in the back of your mind something ticklish is trying to tell you that scaffolds could be better, could do more, could be smarter. But these other people are telling you that no, scaffolds are not better or smarter and don’t have more features because you really really need to customize things yourself.

We agree. With all of you. The built-in Rails scaffolds are meant to be replaced. But something scaffold-like could solve a common pattern in a lot of applications, supposing that something were smarter and cooler with more features. And that’s where ActiveScaffold enters the picture.

Ok, so ActiveScaffold is a solution to a common pattern. Where does that pattern usually show up in applications? How can (should) ActiveScaffold be used?

### Prototyping

This is what the built-in Rails’ scaffold is good for. And ActiveScaffold is even better, because its intelligence and configuration and customization options let your prototype be even better. But it’s all so easy that you shouldn’t feel guilty throwing away the prototype and doing your own thing. In the end we really want to promote the idea that every application has different needs, and if ActiveScaffold doesn’t fit those needs you should replace (or configure/modify) it.

### Admin Interfaces

Your web application is cool because of how it’s been customized and designed for end-user experience. But you usually don’t need to put as much effort into backend stuff. ActiveScaffold is perfect for this, because it’s so easy to whip together some scaffolds and create a backend. Then you can spend your time working on the things that increase your user base and conversion rates.

Granted, ActiveScaffold’s not going to take care of all your backend needs. Sometimes you really ought to pay attention to the backend and customize it for a better workflow. But the backend is often the last thing you want to invest a lot of time into, and ActiveScaffold lets you build a very functional and usable backend … for free.

### Embedded, Widget-Style

Ok, so you’ve maybe got ActiveScaffold running your admin interfaces. Or maybe not. But you’re working on the website design and you come to a page where what you really really need is a miniature ActiveScaffold displaying a subset of data in some table. You’re in luck. You can “embed” ActiveScaffold like a widget in your page while at the same time constraining it to a certain context.

For example, let’s say you’re creating a Major League Baseball website, and you’ve got a page for each team. You’ve also got a table in your database with all the players, and what you really want to do is create a team roster. You could do this with ActiveScaffold, and you could make it pretty slick. You could just add a `<%= render :active_scaffold => 'players', :constraints => {:team_id => 5} -%>` in your page and voila! Instant roster! Ok, but you want to customize it, because you’ve got pictures of all the players. No problem, just override your “picture” field so instead of displaying a useless file name it displays a thumbnail. Ok, but now you want to disable Create and Update because really, end-users shouldn’t be editing the list. Well that’s easy, just use one of the supported authorization methods to disable Create and Update for everyone except logged-in admins.

### Data-Heavy Applications

Let’s face it: sometimes your application just needs a way to manage data, pure and simple. It’s not the entirety of your application, but you need it. This can be a situation similar to one described for embedding, except there’s really not much else to put on the controller except ActiveScaffold. You just want people to log-in and update some records in a database table. Or you have a commercial website selling a variety of thingamabobs, and you want people to browse and pick a thingamabob for their shopping cart. You get the idea. Go for it! Take advantage of all the stuff ActiveScaffold gives you for free, and tweak it for your situation at hand.

## Generator Benefits, Without the Mess

Generators have their upsides and their downsides. And wow, those downsides can really weigh you down. Have you ever tried to update generated code? You don’t, really. The idea behind generators is that they help to get you started, and that you really should own everything they spit out. And that’s cool, because you can tweak and customize and basically get a jump-start on developing your final solution. But in the case of a plugin like ActiveScaffold, you want all the new features we keep adding. You want the patches for the bugs we’ve found. And you don’t want to own the code, you want us to own it. And yet … and yet you still need to tweak things, and go beyond the built-in ActiveScaffold behavior to do your own thing.

Perfect. We want you to go beyond the built-in behavior, too. ActiveScaffold gives you all the customizability of generators without all the drawbacks of maintenance. We call them “overrides”. What can you override? Well this is Ruby, so you can really override anything you want, but that’s not the point here.

### Field Overrides

You can override how stuff gets displayed in the List. Maybe you want to display dates in a different format. Maybe you want to take that file column and display a thumbnail of the actual image, instead of the boring filename. Maybe you want to add some color to the display, highlighting a number in red if it’s below zero. Or maybe you want to add inline editing so people don’t always have to open up a form to change stuff around.

Field overrides are the way. You can define a method with a conventional name and place it in your helper file, and ActiveScaffold will pick it up and use it to replace its default field rendering behavior.

### Form Overrides

Ok, so field overrides work for List, but what if you want to customize Create or Update? What if you want to use a `<textarea>` of a specific size, or you want to create a special `<select>` box that uses JavaScript to dynamically change the options of some other `<select>` box.

Same procedure. You can define a helper method with a conventional name, and ActiveScaffold will depend on it to render the form widget.

### Template Overrides

Ok, yeah, but you’re to the point where you really just need to customize an entire section of the UI. Changing a field here and a form element there just isn’t going to do it. You need a feature we don’t have, and you need it to work a very special way for your application. That’s fine with us, so go ahead and create a template to replace one of ours. ActiveScaffold will give it priority, and you’ll be on your way to a completely custom form layout.

(Really, the first time you create a template override will probably be for _show.rhtml. Our Show view really kinda sucks, because a generic plugin really can’t do much better. You really should customize it.)

### Action Hooks

The next thing you realize is that you don’t need to change something that’s already there, you need to add a whole new action. You need a link on each row that activates a planetary defense system. You need a link on the page that makes it snow in Mexico. Well, um, ok. I guess. You can go ahead and use the same system ActiveScaffold uses to tie all of its actions into the List. You can add your own actions, and hook into your own custom controller logic. Go for it.

## Navigating Documentation

But where can you find out about all these cool features? What is a "method with a conventional name", and which helper file do you put the method in? And why didn’t we go into more detail on this stuff or at least make links everywhere like in Wikipedia?

Meh, maybe we got lazy with the links, but the information you need is right here on the website. The question is how to find it. How is the documentation organized, and how can you find what you need? And what if the docs don't answer your question?

The first thing to find is the [FAQ](/doc/#faq). These are common questions and some mini-tutorials. The next thing you want to do is read some of the [API](/doc/api/). This is a more technical segment of documentation, mostly about the API of the different pieces of ActiveScaffold and some sections that explain how to accomplish common tasks and. So to find options for configuring the List action, check out the [API: List](/doc/api-list/) page. We've tried to sprinkle examples throughout the API, but the emphasis there is more on completeness than friendliness.

And finally, we’ve got some pointers on [how to get help](/doc/help/). Check it out. Join the forums, get involved. We’d love to have you!