# -*- mode: ruby -*-
require 'rake'

desc "local release"
task :release do
  cp "plugin/mixing.rb", "/usr/local/tdiary/plugin"
  cp "plugin/ja/mixing.rb", "/usr/local/tdiary/plugin/ja"
end

desc "local windows release"
task :winrelease do
  cp "plugin/mixing.rb", 'E:\Win32app\ANHTTPD\koichiro\public_html\diary\plugin'
  cp "plugin/ja/mixing.rb", 'E:\Win32app\ANHTTPD\koichiro\public_html\diary\plugin\ja'
end

