{%- from "letsencrypt/map.jinja" import client with context %}

{%- if client.get('enabled', true) %}

include:
  - letsencrypt.client.legacy
  - letsencrypt.client.domain

{%- if client.source.engine == 'pkg' %}

certbot_packages:
  pkg.installed:
    - names: {{ client.source.pkgs }}
    - watch_in:
      - cmd: certbot_installed
    - fromrepo: jessie-backports

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

certbot_cron:
  file.managed:
    - name: /etc/cron.d/certbot
    - source: salt://letsencrypt/files/cron
    - require:
      - cmd: certbot_installed

{%- if grains.get('init', None) == 'systemd' %}

certbot_service:
  file.managed:
    - name: /etc/systemd/system/certbot.service
    - source: salt://letsencrypt/files/certbot.service
    - template: jinja

certbot_timer:
  file.managed:
    - name: /etc/systemd/system/certbot.timer
    - source: salt://letsencrypt/files/certbot.timer
    - require:
      - file: certbot_service

certbot_timer_enabled:
  service.running:
    - name: certbot.timer
    - enable: true
    - watch:
      - file: certbot_timer

{%- endif %}

{%- endif %}
