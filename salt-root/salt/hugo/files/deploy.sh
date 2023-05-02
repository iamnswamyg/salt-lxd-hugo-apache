#!/bin/bash

cd {{ pillar['hugo_deployment_data']['site_repo_name'] }}
git clone https://github.com/xianmin/hugo-theme-jane.git --depth=1 themes/jane
cp -r themes/jane/exampleSite/content ./
cp themes/jane/exampleSite/config.toml ./
sed -i 's|baseURL = "http://localhost:1313/"|baseURL = "http://localhost:8080/"|' config.toml
hugo --destination={{ pillar['hugo_deployment_data']['apache2_document_root'] }}/{{ pillar['hugo_deployment_data']['domain'] }}/public_html