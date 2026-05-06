---
layout: page
title: Frequently Asked Questions
permalink: /faq/
---

{% for faq in site.faqs %}
## [{{ faq.title }}]({{ faq.url }})
{{ faq.excerpt }}
{% endfor %}
