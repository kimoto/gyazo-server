gyazo-server
============

Gyazo Server ruby implement

現在の仕様
---------------
 * 画像のMD5ハッシュ値をファイル名に

使い方
---------------
rackup

    git clone https://github.com/kimoto/gyazo-server.git
    cd ./gyazo-server
    bundle install
    bundle exec rackup

nginx + passenger

    git clone https://github.com/kimoto/gyazo-server.git
    vi nginx.conf
    server {
      listen 80;
      server_name gyazo.example.com
      location / {
        root /path/to/gyazo-server/public/;
        passenger_enabled on;
      }
    }

