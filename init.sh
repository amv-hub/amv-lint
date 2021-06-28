#!/bin/sh

DIR=$(dirname "${BASH_SOURCE[0]}")

cp "$DIR"/.amv_lint.env ./.amv_lint.env
cp "$DIR"/.eslintrc.json ./.eslintrc.json
cp "$DIR"/pre-commit.sh /usr/local/bin/amv
npm i eslint@7.29.0 eslint-plugin-vue@7.11.1 eslint-config-google@0.14.0 babel-eslint @babel/eslint-plugin --save-dev
composer require "squizlabs/php_codesniffer=*" --dev

chmod -R 733 -rf "$DIR"/init.sh