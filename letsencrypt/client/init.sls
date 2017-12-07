{%- from "letsencrypt/map.jinja" import client with context %}

{%- if client.get('enabled', true) %}

include:
  - letsencrypt.client.legacy
  - letsencrypt.client.domain

certbot_packages_openssl:
    pkg.installed:
        - name: {{ client.pkg_openssl }}

{%- if client.source.engine == 'pkg' %}
{% set extra_packages = [] %}
{% if client.auth.method in ("apache", "nginx") %}
    {% set extra_packages = client.source.get("pkgs_" + client.auth.method, []) %}
{% endif %}

certbot_packages:
  pkg.installed:
    - names: {{ client.source.pkgs + extra_packages }}
    - watch_in:
      - cmd: certbot_installed

{%- elif client.source.engine == 'url' %}

certbot_auto_packages:
  pkg.installed:
    - name: wget

certbot_auto_file:
  cmd.run:
    - name: >
        wget --quiet -O {{ client.source.cli }} {{ client.source.url|default('https://dl.eff.org/certbot-auto') }} &&
        chmod +x {{ client.source.cli }}
    - creates: {{ client.source.cli }}
    - watch_in:
      - cmd: certbot_installed
    - require:
      - pkg: certbot_auto_packages

{%- elif client.source.engine == 'docker' %}

certbot_wrapper:
  file.managed:
    - name: /usr/local/bin/certbot
    - source: salt://letsencrypt/files/certbot
    - template: jinja
    - defaults:
        image: {{ client.source.image|default('deliverous/certbot') }}
        conf_dir: {{ client.conf_dir }}
    - mode: 755
    - watch_in:
      - cmd: certbot_installed

{%- endif %}

certbot_installed:
  cmd.wait:
    - name: "{{ client.source.cli }} --non-interactive --version"

{%- if grains.get('init', None) == 'systemd' %}

{%- if client.source.engine != 'pkg' or client.source.install_units %}
certbot_service:
  file.managed:
    - name: /etc/systemd/system/certbot.service
    - source: salt://letsencrypt/files/certbot.service
    - template: jinja

{# reload systemd unit file when it changes #}
certbot_service_available:
  module.watch:
    - name: service.available
    - m_name: certbot.service
    - require:
      - file: certbot_service
    - watch:
      - file: certbot_service
  
certbot_timer:
  file.managed:
    - name: /etc/systemd/system/certbot.timer
    - source: salt://letsencrypt/files/certbot.timer
    - template: jinja
    - require:
      - file: certbot_service
    - watch_in:
      - service: certbot_timer_enabled
{%- endif %}

certbot_timer_enabled:
  service.running:
    - name: certbot.timer
    - enable: true
    - require:
      - cmd: certbot_installed

{%- else %}

certbot_cron:
  file.managed:
    - name: /etc/cron.d/certbot
    - source: salt://letsencrypt/files/cron
    - require:
      - cmd: certbot_installed

{%- endif %}

{%- for hookset, hooks in client.get("hooks", {}).items() %}
{%- for hook in hooks %}
{#- FIXME: Should probably complain if something other than
    pre/post/deploy is given, but I'm not sure how. #}
{%- set basename = hook.split("/") | last %}
certbot_renewal_{{ hookset }}_hook_{{ basename }}:
  file.managed:
    - name: /etc/letsencrypt/renewal-hooks/{{ hookset }}/{{ basename }}
    - source: {{ hook }}
    - template: jinja
    - mode: 700
    - require:
      - cmd: certbot_installed
{%- endfor %}
{%- endfor %}

{%- for hookset, hooks in client.get("pillarhooks", {}).items() %}
{%- for basename in hooks.keys() %}
certbot_renewal_{{ hookset }}_phook_{{ loop.index }}:
  file.managed:
    - name: /etc/letsencrypt/renewal-hooks/{{ hookset }}/{{ basename }}
    - contents_pillar: letsencrypt:client:pillarhooks:{{ hookset }}:{{ basename }}
    - mode: 700
    - require:
      - cmd: certbot_installed
{%- endfor %}
{%- endfor %}

{%- endif %}
