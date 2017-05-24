
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

  If the ``certbot`` package doesn't include Systemd ``.service`` and
  ``.timer`` files, you can set them to be installed by this formula by
  supplying ``install_units: True`` and ``cli``.

  .. code-block:: yaml

      letsencrypt:
        client:
          source:
            engine: pkg
            cli: /usr/bin/certbot
            install_units: true

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
          # Following will produce multidomain certificate:
          site.dummy.org:
            enabled: true
            names:
              - dummy.org
              - www.dummy.org

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

You are able to use multidomain certificates:

.. code-block:: yaml

    letsencrypt:
      client:
        email: sylvain@home
        staging: true
        auth:
          method: apache
        domain:
          keynotdomain:
            enabled: true
            name: ls.opensource-expert.com
            names:
            - www.ls.opensource-expert.com
            - vim22.opensource-expert.com
            - www.vim22.opensource-expert.com
          rm.opensource-expert.com:
            enabled: true
            names:
            - www.rm.opensource-expert.com
          vim7.opensource-expert.com:
            enabled: true
            names:
            - www.vim7.opensource-expert.com
          vim88.opensource-expert.com:
            enabled: true
            names:
            - www.vim88.opensource-expert.com
            - awk.opensource-expert.com
            - www.awk.opensource-expert.com

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

Documentation and Bugs
======================

To learn how to install and update salt-formulas, consult the documentation
available online at:

    http://salt-formulas.readthedocs.io/

In the unfortunate event that bugs are discovered, they should be reported to
the appropriate issue tracker. Use Github issue tracker for specific salt
formula:

    https://github.com/salt-formulas/salt-formula-letsencrypt/issues

For feature requests, bug reports or blueprints affecting entire ecosystem,
use Launchpad salt-formulas project:

    https://launchpad.net/salt-formulas

You can also join salt-formulas-users team and subscribe to mailing list:

    https://launchpad.net/~salt-formulas-users

Developers wishing to work on the salt-formulas projects should always base
their work on master branch and submit pull request against specific formula.

    https://github.com/salt-formulas/salt-formula-letsencrypt

Any questions or feedback is always welcome so feel free to join our IRC
channel:

    #salt-formulas @ irc.freenode.net
