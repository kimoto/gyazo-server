gyazo-server
============

Gyazo Server ruby implement

現在の仕様
---------------
 * 画像のMD5ハッシュ値をファイル名に
 * ファイル数制限対策にファイル名の先頭二文字でディレクトリを掘ります (例: 5fe0703.png => 5/f/5f0703.png)

