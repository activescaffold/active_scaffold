---
layout: home
title: Doc
date: 2025-02-17 13:27:56.000000000 +01:00
permalink: "/doc/"
nav_group: main
nav_order: 3
hero_heading: "ActiveScaffold Docs"
hero_lead: "Search the documentation, browse the knowledge base, or check the FAQ below."
hero_search: true
pagefind: true
---

<div class="home-section">
  <div class="wrapper">
    <h2>Knowledge Base</h2>
    {% assign kb_groups = site.kb | group_by: "category" | sort: "name" %}
    <div class="doc-cards">
      {% for group in kb_groups %}
      <div class="doc-card" id="{{ group.name | default: 'other' | slugify }}">
        <h4>{{ group.name | default: "Other" }}</h4>
        <ul>
          {% assign sorted_items = group.items | sort: "title" %}
        {% for article in sorted_items %}
          <li><a href="{{ article.url | relative_url }}">{{ article.title | escape }}</a></li>
          {% endfor %}
        </ul>
      </div>
      {% endfor %}
    </div>
  </div>
</div>

<div class="home-section home-section--accent">
  <div class="wrapper">
    <h2 id="faq">Frequently Asked Questions</h2>
    <div class="doc-faq">
      {% for faq in site.faqs %}
      <details class="faq-item">
        <summary class="faq-summary">{{ faq.title | escape }}</summary>
        <div class="faq-content">{{ faq.content | markdownify }}</div>
      </details>
      {% endfor %}
    </div>
  </div>
</div>
