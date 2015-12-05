{%- from "letsencrypt/map.jinja" import client with context %}

{%- set monkey_patch_stop = 'service apache2 stop;service nginx stop;' %}
{%- set monkey_patch_start = ';service apache2 start;service nginx start;' %}

{%- if client.enabled %}

letsencrypt-packages:
  pkg.installed:
  - names: {{ client.pkgs }}

letsencrypt-config:
  file.managed:
    - name: /etc/letsencrypt/cli.ini
    - makedirs: true
    - contents_pillar: letsencrypt:client:config

letsencrypt-client-git:
  git.latest:
    - name: https://github.com/letsencrypt/letsencrypt
    - target: {{ client.cli_install_dir }}

{% for setname, domainlist in client.domainset.items() %}
create-initial-cert-{{ setname }}-{{ domainlist[0] }}:
  cmd.run:
    - unless: ls /etc/letsencrypt/live/{{ domainlist[0] }}
    - name: {{ monkey_patch_stop }}{{ client.cli_install_dir }}/letsencrypt-auto -d {{ domainlist|join(' -d ') }} certonly{{ monkey_patch_start }}
    - require:
      - file: letsencrypt-config

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.present:
    - name: {{ monkey_patch_stop }}{{ client.cli_install_dir }}/letsencrypt-auto -d {{ domainlist|join(' -d ') }} certonly{{ monkey_patch_start }}
    - month: '*/2'
    - minute: random
    - hour: random
    - daymonth: random
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist[0] }}


{% endfor %}

{%- endif %}
