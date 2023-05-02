hugo_group:
  group.present:
    - name: {{ pillar['hugo_deployment_data']['group'] }}

hugo_user:
  user.present:
    - name: {{ pillar['hugo_deployment_data']['user'] }}
    - gid: {{ pillar['hugo_deployment_data']['group'] }}
    - home: {{ pillar['hugo_deployment_data']['home_dir'] }}
    - createhome: True
    - require:
      - group: hugo_group

hugo_site_repo:
  cmd.run:
    - name: git clone --recurse-submodules https://github.com/{{ pillar['hugo_deployment_data']['github_account'] }}/{{ pillar['hugo_deployment_data']['site_repo_name'] }}.git
    - cwd: {{ pillar['hugo_deployment_data']['home_dir'] }}
    - runas: {{ pillar['hugo_deployment_data']['user'] }}
    - creates: {{ pillar['hugo_deployment_data']['home_dir'] }}/{{ pillar['hugo_deployment_data']['site_repo_name'] }}
    - require:
      - pkg: git_pkg
      - user: hugo_user

Turn Off KeepAlive:
  file.replace:
    - name: /etc/apache2/apache2.conf
    - pattern: 'KeepAlive On'
    - repl: 'KeepAlive Off'
    - show_changes: True
    - require:
      - pkg: apache2_pkg

/etc/apache2/conf-available/tune_apache.conf:
  file.managed:
    - source: salt://hugo/files/tune_apache.conf
    - require:
      - pkg: apache2_pkg

Enable tune_apache:
  apache_conf.enabled:
    - name: tune_apache
    - require:
      - pkg: apache2_pkg

apache2_document_root:
  file.directory:
    - name: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}
    - user: {{ pillar['hugo_deployment_data']['user'] }}
    - group: {{ pillar['hugo_deployment_data']['group'] }}
    - dir_mode: 0755
    - require:
      - user: hugo_user

apache2_document_publichtml:
  file.directory:
    - name: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/public_html
    - user: {{ pillar['hugo_deployment_data']['user'] }}
    - group: {{ pillar['hugo_deployment_data']['group'] }}
    - dir_mode: 0755
    - require:
      - user: hugo_user

apache2_document_log:
  file.directory:
    - name: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/log
    - user: {{ pillar['hugo_deployment_data']['user'] }}
    - group: {{ pillar['hugo_deployment_data']['group'] }}
    - dir_mode: 0755
    - require:
      - user: hugo_user

apache2_document_backups:
  file.directory:
    - name: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/backups
    - user: {{ pillar['hugo_deployment_data']['user'] }}
    - group: {{ pillar['hugo_deployment_data']['group'] }}
    - dir_mode: 0755
    - require:
      - user: hugo_user

000-default:
  apache_site.disabled:
    - require:
      - pkg: apache2

/etc/apache2/sites-available/{{ pillar['hugo_deployment_data']['domain'] }}.conf:
  apache.configfile:
    - config:
      - VirtualHost:
          this: '*:80'
          ServerName:
            - {{ pillar['hugo_deployment_data']['domain'] }}
          ServerAlias:
            - www.{{ pillar['hugo_deployment_data']['domain'] }}
          DocumentRoot: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/public_html
          ErrorLog: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/log/error.log
          CustomLog: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/log/access.log combined

Enable {{ pillar['hugo_deployment_data']['domain'] }} site:
  apache_site.enabled:
    - name: {{ pillar['hugo_deployment_data']['domain'] }}
    - require:
      - pkg: apache2_pkg


build_script:
  file.managed:
    - name: {{ pillar['hugo_deployment_data']['home_dir'] }}/deploy.sh
    - source: salt://hugo/files/deploy.sh
    - user: {{ pillar['hugo_deployment_data']['user'] }}
    - group: {{ pillar['hugo_deployment_data']['group'] }}
    - mode: 0755
    - template: jinja
    - require:
      - user: hugo_user
  
  cmd.run:
    - name: ./deploy.sh
    - cwd: {{ pillar['hugo_deployment_data']['home_dir'] }}
    - runas: {{ pillar['hugo_deployment_data']['user'] }}
    - creates: {{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/public_html/index.html
    - require:
      - file: build_script
      - cmd: hugo_site_repo
      - file: apache2_document_publichtml