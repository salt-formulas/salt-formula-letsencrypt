{%- from "letsencrypt/map.jinja" import client with context %}

{#- global staging #}
{%- if client.get('staging', false) %}
{%-   set staging = '--staging' %}
{%- else %}
{%-   set staging = '' %}
{%- endif %}

{%- for domain, params in client.get('domain', {}).iteritems() %}
{%- if params.get('enabled', true) %}
{%- set auth = params.auth|default(client.auth) %}

certbot_{{ domain }}:
  cmd.run:
    - name: >
        certbot certonly {{ staging }} --non-interactive --agree-tos --no-self-upgrade --email {{ params.email|default(client.email) }}
        {%- if auth.method == 'standalone' %}
        --standalone --standalone-supported-challenges {{ auth.type }} --http-01-port {{ auth.port }}
        {%- elif auth.method == 'webroot' %}
        --webroot --webroot-path {{ auth.path }}
        {%- elif auth.method in ['apache', 'nginx'] %}
        --{{ auth.method }}
        {%- endif %}
        -d {{ params.name|default(domain) }}
        {%- for d in params.get('multi', []) %}
        -d {{ d }}
        {%- endfor %}
    - creates: {{ client.conf_dir }}/live/{{ params.name|default(domain) }}/cert.pem
    - require:
      - cmd: certbot_installed

{%- else %}

certbot_{{ domain }}_renew_absent:
  file.absent:
    - name: {{ client.conf_dir }}/renewal/{{ domain }}.conf

certbot_{{ domain }}_live_absent:
  file.absent:
    - name: {{ client.conf_dir }}/live/{{ domain }}

certbot_{{ domain }}_archive_absent:
  file.absent:
    - name: {{ client.conf_dir }}/archive/{{ domain }}

{%- endif %}
{%- endfor %}
