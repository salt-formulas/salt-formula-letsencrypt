
=============
Let's Encrypt
=============

Service letsencrypt description

Sample pillars
==============

.. code-block:: yaml

    letsencrypt:
      client:
        enabled: true
        config: |
          host = https://acme-v01.api.letsencrypt.org/directory
          email = webmaster@example.com
          authenticator = webroot
          webroot-path = /var/lib/www
          agree-tos = True
          renew-by-default = True
        domainset:
          www:
            - example.com
            - www.example.com
          mail:
            - imap.example.com
            - smtp.example.com
            - mail.example.com
          intranet:
            - intranet.example.com

Example of authentication via another port without stopping nginx server::

    location /.well-known/acme-challenge/ {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://{{ site.host.name }}:9999/.well-known/acme-challenge/;
    }

.. code-block:: yaml

    letsencrypt:
      client:
        enabled: true
        config: |
          ...
          renew-by-default = True
          http-01-port = 9999
          standalone-supported-challenges = http-01
        domainset:
          www:
            - example.com


Read more
=========

* links
