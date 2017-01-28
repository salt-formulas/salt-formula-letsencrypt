{%- from "letsencrypt/map.jinja" import client with context %}

{%- if client.enabled %}

{%- if client.source.engine == 'pkg' %}

certbot_packages:
  pkg.installed:
    - names: {{ client.source.pkgs }}
    - watch_in:
      - cmd: certbot_installed

{%- elif client.source.engine == 'url' %}

certbot_auto_file:
  file.managed:
    - name: {{ client.source.cli }}
    - source: {{ client.source.url|default('https://dl.eff.org/certbot-auto') }}
    - replace: true
    - mode: 755
    - watch_in:
      - cmd: certbot_installed

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
    - name: "{{ client.source.cli }} --version"

letsencrypt-config:
  file.managed:
    - name: {{ client.conf_dir }}/cli.ini
    - makedirs: true
    - contents_pillar: letsencrypt:client:config

/usr/local/bin/check_letsencrypt_cert.sh:
  file.managed:
    - mode: 755
    - contents: |
        #!/bin/bash
        FIRST_CERT=$1

        for DOMAIN in "$@"
        do
            openssl x509 -in {{ client.conf_dir }}/live/$1/cert.pem -noout -text | grep DNS:${DOMAIN} > /dev/null || exit 1
        done
        CERT=$(date -d "$(openssl x509 -in {{ client.conf_dir }}/live/$1/cert.pem -enddate -noout | cut -d'=' -f2)" "+%s")
        CURRENT=$(date "+%s")
        REMAINING=$((($CERT - $CURRENT) / 60 / 60 / 24))
        [ "$REMAINING" -gt "30" ] || exit 1
        echo Domains $@ are in cert and cert is valid for $REMAINING days

{% for setname, domainlist in client.domainset.items() %}
create-initial-cert-{{ setname }}-{{ domainlist[0] }}:
  cmd.run:
    - unless: /usr/local/bin/check_letsencrypt_cert.sh {{ domainlist|join(' ') }}
    - name: {{ client.source.cli }} -d {{ domainlist|join(' -d ') }} certonly
    - require:
      - file: letsencrypt-config
      - cmd: certbot_installed

letsencrypt-crontab-{{ setname }}-{{ domainlist[0] }}:
  cron.present:
    - name: /usr/local/bin/check_letsencrypt_cert.sh {{ domainlist|join(' ') }} > /dev/null || {{ client.source.cli }} -d {{ domainlist|join(' -d ') }} certonly
    - month: '*'
    - minute: random
    - hour: random
    - dayweek: '*'
    - identifier: letsencrypt-{{ setname }}-{{ domainlist[0] }}
    - require:
      - cmd: create-initial-cert-{{ setname }}-{{ domainlist[0] }}
{% endfor %}

{%- endif %}
