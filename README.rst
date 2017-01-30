
=============
Let's Encrypt
=============

Service letsencrypt description

Sample pillars
==============

Installation
------------

There are 3 installation methods available:

- package (default for Debian)

  For Debian Jessie, you need to use jessie-backports repository. For Ubuntu,
  use Launchpad PPA providing certbot package. You can use linux formula to
  manage these APT sources.

  .. code-block:: yaml

      letsencrypt:
        client:
          source:
            engine: pkg

- URL to certbot-auto (default)

  This is default installation method for systems with no available certbot
  package.

  .. code-block:: yaml

      letsencrypt:
        client:
          source:
            engine: url
            url: "https://dl.eff.org/certbot-auto"

- Docker container

  Alternate installation method where Docker image is used to provide certbot
  tool and executed using wrapper script.

  .. code-block:: yaml

      letsencrypt:
        client:
          source:
            engine: docker
            image: "deliverous/certbot"

Usage
-----

Default authentication method using standalone server on specified port.
But this won't work without configuration of apache/nginx (read on) unless you
don't have webserver running so you can select port 80 or 443.

.. code-block:: yaml

    letsencrypt:
      client:
        email: root@dummy.org
        auth:
          method: standalone
          type: http-01
          port: 9999
        domain:
          dummy.org:
            enabled: true
          www.dummy.org:
            enabled: true

However ACME server always visits port 80 (or 443) where most likely Apache or
Nginx is listening. This means that you need to configure
``/.well-known/acme-challenge/`` to proxy requests on localhost:9999.
For example, ensure you have following configuration for Apache:

::

  ProxyPass "/.well-known/acme-challenge/" "http://127.0.0.1:9999/.well-known/acme-challenge/" retry=1
  ProxyPassReverse "/.well-known/acme-challenge/" "http://127.0.0.1:9999/.well-known/acme-challenge/"

  <Location "/.well-known/acme-challenge/">
    ProxyPreserveHost On
    Order allow,deny
    Allow from all
    Require all granted
  </Location>

You can also use ``apache`` or ``nginx`` auth methods and let certbot do
what's needed, this should be the simplest option.

.. code-block:: yaml

    letsencrypt:
      client:
        auth: apache

Alternatively you can use webroot authentication (using eg. existing apache
installation serving directory for all sites):

.. code-block:: yaml

    letsencrypt:
      client:
        auth:
          method: webroot
          path: /var/www/html
          port: 80
        domain:
          dummy.org:
            enabled: true
          www.dummy.org:
            enabled: true

It's also possible to override auth method or other options only for single
domain:

.. code-block:: yaml

    letsencrypt:
      client:
        email: root@dummy.org
        auth:
          method: standalone
          type: http-01
          port: 9999
        domain:
          dummy.org:
            enabled: true
            auth:
              method: webroot
              path: /var/www/html/dummy.org
              port: 80
          www.dummy.org:
            enabled: true

Legacy configuration
--------------------

Common metadata:

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

* `Certbot authentication plugins <https://letsencrypt.readthedocs.io/en/latest/using.html#getting-certificates-and-choosing-plugins>`_
