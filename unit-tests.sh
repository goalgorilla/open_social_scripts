#!/usr/bin/env bash

php -d xdebug.extended_info=0 -d xdebug.remote_autostart=0 -d xdebug.coverage_enable=0 -d xdebug.profiler_enable=0 -d xdebug.remote_enable=0 /var/www/vendor/bin/phpunit -c /var/www/html/core/phpunit.xml.dist --testsuite unit --group social
