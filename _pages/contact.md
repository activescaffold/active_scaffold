---
layout: page
title: Contact
date: 2025-02-24 13:06:26.000000000 +01:00
permalink: "/contact/"
hero_heading: Contact
hero_lead: Fill out the form to get in touch
---

<div class="contact-columns">

  <div class="contact-col">
    <h3>Contributing to ActiveScaffold</h3>
    <p>We welcome contributions! Here are some ways to get involved:</p>
    <ul>
      <li>Edit translations directly on the <a href="http://www.localeapp.com/projects/public?search=active_scaffold">active_scaffold</a> project on Locale. The maintainer will pull translations from Locale and push to GitHub.</li>
      <li>Report bugs or suggest features on <a href="https://github.com/activescaffold/active_scaffold/issues">GitHub Issues</a>.</li>
      <li>Submit pull requests — check the <a href="https://github.com/activescaffold/active_scaffold/wiki">wiki</a> for contribution guidelines.</li>
    </ul>
    <p>Happy contributing!</p>
  </div>

  <div class="contact-col">
    <h3>Reach us!</h3>
	<div data-fs-success></div>
	<div data-fs-error></div>
    <form class="contact-form" id="contact-form">
      <div class="contact-field">
        <label for="contact-name">Name</label>
        <input type="text" id="contact-name" name="name">
      </div>
      <div class="contact-field">
        <label for="contact-email">E-Mail</label>
        <input type="email" id="contact-email" name="email" required>
        <span data-fs-error="email"></span>
      </div>
      <div class="contact-field">
        <label for="contact-message">Message</label>
        <textarea id="contact-message" name="message" rows="6" required></textarea>
        <span data-fs-error="message"></span>
      </div>
      <div class="g-recaptcha" data-sitekey="6LdQHsAsAAAAAMLV4GB0uZ7EkA_RtZvpA2KF7jjO"></div>
      <input type="hidden" name="_subject" value="New contact for ActiveScaffold">
      <button type="submit" class="contact-submit">Send</button>
    </form>
  </div>

</div>
<script src="https://www.google.com/recaptcha/enterprise.js" async defer></script>
<script>
  window.formspree = window.formspree || function () { (formspree.q = formspree.q || []).push(arguments); };
  formspree('initForm', { formElement: '#contact-form', formId: 'myklplqg' });
</script>
<script src="https://unpkg.com/@formspree/ajax@1" defer></script>
