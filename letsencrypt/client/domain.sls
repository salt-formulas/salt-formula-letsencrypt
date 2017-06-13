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
{%- set main_domain = params.name|default(domain) %}
{%- set cert_path = client.conf_dir + '/live/' + main_domain + '/cert.pem' %}
{%- set subject_alternative_names = ['DNS:' + main_domain] %}
{%- for n in params.get('names', []) %}
    {%- set n = 'DNS:' + n %}
    {%- if n not in subject_alternative_names %}
        {%- do subject_alternative_names.append(n) %}
    {%- endif %}
{%- endfor %}
{%- set subject_alternative_names = subject_alternative_names|sort|join(', ') %}
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
        -d {{ main_domain }}
        {%- for d in params.get('names', []) %}
        -d {{ d }}
        {%- endfor %}
        --expand
    {#- Check if there are missing cert file or it has missing domains, to (re)issue certificate. #}
    {#- Please note only expanding certificate (adding domains) works. #}
    - unless: test -e "{{ cert_path }}" && openssl x509 -text -in "{{ cert_path }}" | fgrep -q -e"{{ subject_alternative_names }}"
    {%- if grains.get('noservices') %}
    - onlyif: /bin/false
    {%- endif %}
    - require:
      - cmd: certbot_installed
      - pkg: certbot_packages_openssl
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
