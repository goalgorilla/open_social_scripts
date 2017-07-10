#!/usr/bin/env bash

ls -lah html/sites/default
sudo chown -R travis:travis html
chmod 755 html/sites/default
chmod 755 html/sites/default/*
chmod -R 777 html/sites/default/files
