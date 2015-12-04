{%- if pillar.letsencrypt is defined %}
include:
{%- if pillar.letsencrypt.client is defined %}
- letsencrypt.client
{%- endif %}
{%- endif %}
