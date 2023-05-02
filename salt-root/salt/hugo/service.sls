apache2_service:
  service.running:
    - name: apache2
    - enable: True
    - reload: True
    - watch:
      - pkg: apache2_pkg
    