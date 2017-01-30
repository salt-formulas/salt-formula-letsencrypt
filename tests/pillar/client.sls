letsencrypt:
  client:
    enabled: true
    email: root@localhost
    auth:
      method: standalone
      type: http-01
      port: 9999
    domain:
      dummy.org:
        enabled: true
      www.dummy.org:
        enabled: true
        auth:
          method: webroot
          path: /var/www/html
          port: 80
      olddomain.org:
        enabled: false
