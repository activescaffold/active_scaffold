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
    {% for group in kb_groups %}
    <div class="doc-kb-group">
      {% if group.name != "" %}
      <h3 class="doc-kb-group__title">{{ group.name }}</h3>
      {% endif %}
      <div class="doc-cards">
        {% for article in group.items %}
        <a href="{{ article.url | relative_url }}" class="doc-card">
          <h4>{{ article.title | escape }}</h4>
          <p>{{ article.excerpt | strip_html | truncatewords: 20 }}</p>
        </a>
        {% endfor %}
      </div>
    </div>
    {% endfor %}
  </div>
</div>

<div class="home-section home-section--accent">
  <div class="wrapper">
    <h2>Frequently Asked Questions</h2>
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
