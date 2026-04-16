---
layout: page
title: Blog
nav_group: main
nav_order: 0
hero_heading: Blog
hero_lead: Stay up to date with the latest news, updates, and best practices for using ActiveScaffold in your Ruby on Rails applications.
permalink: /blog/
pagination:
  enabled: true
---

<nav class="blog-filters">
  <a href="{{ '/blog/' | relative_url }}" class="blog-filter active">All</a>
  {% assign sorted_cats = site.categories | sort %}
  {% for category in sorted_cats %}
  {% assign cat_slug = category[0] | slugify %}
  <a href="{{ '/category/' | append: cat_slug | append: '/' | relative_url }}"
     class="blog-filter">{{ category[0] }}</a>
  {% endfor %}
</nav>

<div class="blog-posts">
  {% for post in paginator.posts %}
  <article class="blog-post-item">
    <div class="blog-post-meta">
      <time datetime="{{ post.date | date: "%Y-%m-%d" }}">{{ post.date | date: "%B %-d, %Y" }}</time>
      {% for cat in post.categories %}
      <span class="blog-post-cat">{{ cat }}</span>
      {% endfor %}
    </div>
    <h2><a href="{{ post.url | relative_url }}">{{ post.title | escape }}</a></h2>
    <p>{{ post.excerpt | strip_html | truncatewords: 30 }}</p>
    <a href="{{ post.url | relative_url }}" class="blog-read-more">Read More &rarr;</a>
  </article>
  {% endfor %}
</div>

{% if paginator.total_pages > 1 %}
<nav class="blog-pagination" aria-label="Blog pagination">
  {% if paginator.previous_page %}
  <a href="{{ paginator.previous_page_path | relative_url }}" class="blog-page-link">&laquo; Newer</a>
  {% else %}
  <span class="blog-page-link blog-page-link--disabled">&laquo; Newer</span>
  {% endif %}

  <span class="blog-page-info">Page {{ paginator.page }} of {{ paginator.total_pages }}</span>

  {% if paginator.next_page %}
  <a href="{{ paginator.next_page_path | relative_url }}" class="blog-page-link">Older &raquo;</a>
  {% else %}
  <span class="blog-page-link blog-page-link--disabled">Older &raquo;</span>
  {% endif %}
</nav>
{% endif %}
