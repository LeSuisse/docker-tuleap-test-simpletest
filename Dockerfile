### Quick & dirty work. Seems to work.

## Re-use tuleap base for caching ##
FROM centos:centos6

MAINTAINER Thomas Gerbet <thomas.gerbet@enalean.com>

RUN rpm -i http://dl.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm && \
    rpm -i http://rpms.famillecollet.com/enterprise/remi-release-6.rpm && \
    rpm --import http://apt.sw.be/RPM-GPG-KEY.dag.txt && \
    rpm -i http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.3-1.el6.rf.x86_64.rpm

COPY *.repo /etc/yum.repos.d/

# Uncomment when EPEL start shitting bricks (like 404)
# RUN sed -i 's/#baseurl/baseurl/' /etc/yum.repos.d/epel.repo
# RUN sed -i 's/mirrorlist/#mirrorlist/' /etc/yum.repos.d/epel.repo

# Tuleap essentials
RUN yum -y install --enablerepo=remi --enablerepo=rpmforge-extras \
    php-restler \
    mysql-server \
    php-zendframework \
    php-pecl-xdebug \
    htmlpurifier \
    jpgraph-tuleap \
    php-pear-Mail-mimeDecode \
    rcs \
    cvs \
    php-guzzle \
    unzip \
    tar \
    subversion \
    bzip2 \
    git

# PHP compilation tools
RUN yum -y install \
    autoconf \
    gcc-c++ \
    glibc-devel \
    openssl-devel \
    bison \
    re2c \
    libicu-devel \
    libxml2-devel \
    libpng-devel \
    libjpeg-devel

# PHP source clone
RUN git clone https://github.com/php/php-src.git --depth=1

# PHP compilation
RUN cd php-src && \
    ./buildconf -f && \
    ./configure \
        --enable-mbstring \
        --enable-soap \
        --enable-intl \
        --enable-xmlreader \
        --with-openssl \
        --with-gd \
        --with-pear \
        --with-mysqli=mysqlnd && \
    make --quiet && \
    make install

# Cleanup
RUN rm -rf php-src && \
    yum -y remove \
        autoconf \
        gcc-c++ \
        glibc-devel \
        openssl-devel \
        bison \
        re2c \
        libicu-devel \
        libxml2-devel \
        libpng-devel \
        libjpeg-devel && \
    yum clean all

RUN git config --global user.email "ut@tuleap.org" && git config --global user.name "Unit test runner"

RUN service mysqld start && sleep 1 && mysql -e "GRANT ALL PRIVILEGES on *.* to 'integration_test'@'localhost' identified by 'welcome0'"

COPY run.sh /run.sh
ENTRYPOINT ["/run.sh"]

CMD ["-x", "/tuleap/tests/simpletest", "/tuleap/plugins", "/tuleap/tests/integration"]

VOLUME ["/tuleap"]
