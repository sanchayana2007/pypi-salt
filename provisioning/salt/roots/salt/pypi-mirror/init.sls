
include:
  - python.27.virtualenv
  - nginx

pypi-mirror:
  user.present:
    - home: /opt/bandersnatch

/data/pypi-mirror:
  file.directory:
    - user: pypi-mirror
    - group: pypi-mirror
    - mode: 755
    - makedirs: True
    - require:
      - user: pypi-mirror

/var/log/nginx/pypi-mirror:
  file.directory:
    - user: root
    - group: root
    - makedirs: True

/etc/nginx/conf.d/bandersnatch.conf:
  file.managed:
    - source: salt://pypi-mirror/config/bandersnatch.nginx.conf
    - template: jinja
    - context:
      server_names: {{ salt['pillar.get']('bandersnatch:server_names', ['_']) }}
    - user: root
    - group: root
    - mode: 640
    - makedirs: True
    - require:
      - file: /var/log/nginx/pypi-mirror

/etc/logrotate.d/pypi-mirror:
  file.managed:
    - source: salt://pypi-mirror/config/bandersnatch.logrotate.conf
    - user: root
    - group: root
    - mode: 644
    - makedirs: True
  
/opt/bandersnatch:
  file.directory:
    - user: pypi-mirror
    - group: pypi-mirror
    - mode: 750
    - makedirs: True
    - recurse:
      - user
      - group
    - require:
      - user: pypi-mirror
  virtualenv.managed:
    - venv_bin: virtualenv-2.7
    - python: python2.7
    - system_site_packages: False
    - user: pypi-mirror
    - require:
      - file: /opt/bandersnatch
      - user: pypi-mirror
      - pip: virtualenv-2.7

bandersnatch:
  pip.installed:
    - name: bandersnatch == 1.0.5
    - bin_env: /opt/bandersnatch
    - require:
      - virtualenv: /opt/bandersnatch

/etc/bandersnatch.conf:
  file.managed:
    - source: salt://pypi-mirror/config/bandersnatch.conf.jinja
    - template: jinja

{% if 'develop' in grains['roles'] %}
{% if not salt['file.directory_exists']('/data/pypi-mirror/web') %}
bandersnatch_short_sync:
  cmd.run:
    - name: '( /opt/bandersnatch/bin/bandersnatch mirror ) & sleep 30; kill $!'
    - cwd: /opt/bandersnatch
    - user: pypi-mirror
    - require:
      - file: /etc/bandersnatch.conf
      - virtualenv: /opt/bandersnatch
{% endif %}
{% endif %}

/etc/cron.d/pypi-mirror:
  file.managed:
    - source: salt://pypi-mirror/config/crontab.jinja
    - template: jinja
    - require:
      - file: /etc/bandersnatch.conf
      - virtualenv: /opt/bandersnatch
