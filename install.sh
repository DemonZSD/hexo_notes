# /bin/bash

yum install -y gcc gcc-c++ make git openssl 
yum install -y epel-release

yum clean all && yum makecache fast
yum install -y nginx
systemctl enable nginx and systemctl start nginx
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.34.0/install.sh | bash


nvm install stable
npm install -g hexo-cli

# install plugins
npm install --save hexo-generator-feed
npm install gulp -g
npm install gulp-minify-css gulp-uglify gulp-htmlmin gulp-htmlclean gulp --save
npm install hexo-wordcount --save
npm install hexo-generator-searchdb --save