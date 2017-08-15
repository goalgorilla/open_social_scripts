#!/bin/sh

# Create the workspace.
mkdir /workspace
cd /workspace

# Clone all needed repositories.
git clone https://github.com/klausi/pareviewsh.git pareviewsh
git clone --branch master http://git.drupal.org/sandbox/coltrane/1921926.git drupalsecure
git clone --branch master https://github.com/lucasdemarchi/codespell.git

# Create some symlinks.
ln -s /workspace/pareviewsh/pareview.sh /usr/local/bin
ln -s /var/www/vendor/squizlabs/php_codesniffer/scripts/phpcs /usr/local/bin

# PHP CS settings.
phpcs --config-set installed_paths /var/www/vendor/drupal/coder/coder_sniffer,/workspace/drupalsecure

# Codespell settings and symlink.
cp /workspace/codespell/bin/codespell /workspace/codespell/codespell
ln -s /workspace/codespell/codespell /usr/local/bin/codespell

# Install node for eslint.
apt-get install npm
ln -s /usr/bin/nodejs /usr/bin/node
npm cache clean -f
npm install -g n
n stable
npm i -g eslint

# Run it, and output to: social.dev/pareview.html
pareview.sh /var/www/html/profiles/contrib/social/ > /var/www/html/pareview.html
