{%- from "letsencrypt/map.jinja" import client with context %}

{#
  This state covers backward compatibility with older version of formula with
  different metadata structure
#}

{%- if client.config is defined %}
{# XXX: Obsolete way, defining whole config file #}

letsencrypt-config:
  file.managed:
    - name: {{ client.conf_dir }}/cli.ini
    - makedirs: true
    - contents_pillar: letsencrypt:client:config

{%- endif %}

{%- if client.domainset is defined %}
{# XXX: Obsolete way, using domainset structure #}

{% for setname, domainlist in client.domainset.items() %}
create-initial-cert-{{ setname }}-{{ domainlist[0] }}:
  cmd.run:
    - unless: /usr/local/bin/check_letsencrypt_cert.sh {{ domainlist|join(' ') }}
    - name: {{ client.source.cli }} -d {{ domainlist|join(' -d ') }} certonly
    - require:
      - file: letsencrypt-config
      - cmd: certbot_installed

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.absent:
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
{% endfor %}

{%- endif %}
