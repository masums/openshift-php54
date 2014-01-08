#!/bin/sh

OPENSHIFT_RUNTIME_DIR=$OPENSHIFT_HOMEDIR/app-root/runtime
OPENSHIFT_REPO_DIR=$OPENSHIFT_HOMEDIR/app-root/runtime/repo

# INSTALL APACHE
cd $OPENSHIFT_RUNTIME_DIR
mkdir srv
mkdir srv/pcre
mkdir srv/httpd
mkdir srv/httpd/conf
mkdir srv/php
mkdir tmp
cd tmp/
wget -nc http://ftp.halifax.rwth-aachen.de/apache/httpd/httpd-2.4.7.tar.gz
tar -zxf httpd-2.4.7.tar.gz
wget -nc http://artfiles.org/apache.org/apr/apr-1.5.0.tar.gz
tar -zxf apr-1.5.0.tar.gz
mv apr-1.5.0 httpd-2.4.7/srclib/apr
wget -nc http://artfiles.org/apache.org/apr/apr-util-1.5.3.tar.gz
tar -zxf apr-util-1.5.3.tar.gz
mv apr-util-1.5.3 httpd-2.4.7/srclib/apr-util
wget -nc ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.34.tar.gz
tar -zxf pcre-8.34.tar.gz
cd pcre-8.34
./configure \
--prefix=$OPENSHIFT_RUNTIME_DIR/srv/pcre
make && make install
cd ../httpd-2.4.7
./configure \
--prefix=$OPENSHIFT_RUNTIME_DIR/srv/httpd \
--with-included-apr \
--with-pcre=$OPENSHIFT_RUNTIME_DIR/srv/pcre \
--enable-so \
--enable-auth-digest \
--enable-rewrite \
--enable-setenvif \
--enable-mime \
--enable-deflate \
--enable-headers
make && make install
cd ..

# INSTALL PHP
wget -nc http://download.icu-project.org/files/icu4c/50.1/icu4c-50_1-src.tgz
tar -zxf icu4c-50_1-src.tgz
cd icu/source/
chmod +x runConfigureICU configure install-sh
./configure \
--prefix=$OPENSHIFT_RUNTIME_DIR/srv/icu/
make && make install
cd ../..
wget -nc http://zlib.net/zlib-1.2.8.tar.gz
tar -zxf zlib-1.2.8.tar.gz
cd zlib-1.2.8
chmod +x configure
./configure \
--prefix=$OPENSHIFT_RUNTIME_DIR/srv/zlib/
make && make install
cd ../..
wget -nc http://au1.php.net/get/php-5.5.7.tar.gz/from/this/mirror
tar -zxf php-5.5.7.tar.gz
cd php-5.5.7
./configure \
--with-libdir=lib64 \
--prefix=$OPENSHIFT_RUNTIME_DIR/srv/php/ \
--with-config-file-path=$OPENSHIFT_RUNTIME_DIR/srv/php/etc/apache2 \
--with-layout=PHP \
--with-zlib=$OPENSHIFT_RUNTIME_DIR/srv/zlib \
--with-gd \
--enable-zip \
--with-apxs2=$OPENSHIFT_RUNTIME_DIR/srv/httpd/bin/apxs \
--enable-mbstring \
--enable-intl \
--with-icu-dir=$OPENSHIFT_RUNTIME_DIR/srv/icu
make && make install
mkdir $OPENSHIFT_RUNTIME_DIR/srv/php/etc/apache2
cd ..
wget -nc http://pecl.php.net/get/APC-3.1.13.tgz
tar -zxf APC-3.1.13.tgz
cd APC-3.1.13
$OPENSHIFT_RUNTIME_DIR/srv/php/bin/phpize
./configure \
--with-php-config=$OPENSHIFT_RUNTIME_DIR/srv/php/bin/php-config \
--enable-apc \
--enable-apc-debug=no
make && make install

# COPY TEMPLATES
cp $OPENSHIFT_REPO_DIR/misc/templates/bash_profile.tpl $OPENSHIFT_HOMEDIR/app-root/data/.bash_profile
cp $OPENSHIFT_REPO_DIR/misc/templates/php.ini.tpl $OPENSHIFT_RUNTIME_DIR/srv/php/etc/apache2/php.ini
python $OPENSHIFT_REPO_DIR/misc/httpconf.py

# START APACHE
$OPENSHIFT_RUNTIME_DIR/srv/httpd/bin/apachectl start
