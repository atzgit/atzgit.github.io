---
layout: default
title: Home
permalink: /readme/ 
---

# Hello  
ATZ website  
Welcome!  

# PAGE LIST  
{% for page in site.pages %}
{% if page.path contains 'pages/' %}
- [{{ page.title | default: page.name }}]({{ page.url }})
{% endif %}
{% endfor %}
* [Orther link](https://google.com)



<p>By @{{ site.github.owner_name }}</p>
<p>
  <a href="/pages/about.html"><img src="https://raw.githubusercontent.com/atzgit/atzgit.github.io/main/assets/logo16.png" width="16" /></a> <a href="/pages/about.html">About</a>
  &mdash;
  <a href="https://github.com/{{ site.github.owner_name }}/" target="_blank" rel="noopener noreferrer">Project</a> 
  &mdash;
  <a href="https://github.com/pages-themes" target="_blank" rel="noopener noreferrer">Theme</a>
</p>
