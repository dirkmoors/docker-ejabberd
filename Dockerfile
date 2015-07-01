FROM debian:jessie
MAINTAINER Rafael Römhild <rafael@roemhild.de>

ENV EJABBERD_BRANCH master
ENV ERLANG_VERSION 17.5
ENV EJABBERD_USER ejabberd
ENV EJABBERD_WEB_ADMIN_SSL true
ENV EJABBERD_STARTTLS true
ENV EJABBERD_S2S_SSL true
ENV EJABBERD_HOME /opt/ejabberd
ENV HOME $EJABBERD_HOME
ENV PATH $EJABBERD_HOME/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV DEBIAN_FRONTEND noninteractive
ENV XMPP_DOMAIN localhost

# Set kerl configuration options
ENV KERL_CONFIGURE_OPTIONS "--enable-smp-support \
                            --enable-m64-build \
                            --enable-kernel-poll \
                            --without-javac \
                            --disable-native-libs \
                            --disable-hipe \
                            --disable-sctp \
                            --enable-threads"

# Set default locale for the environment
ENV LC_ALL C.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# Add ejabberd user and group
RUN groupadd -r $EJABBERD_USER \
    && useradd -r -m \
       -g $EJABBERD_USER \
       -d $EJABBERD_HOME \
       $EJABBERD_USER

# Add erlang install helper (source: http://docs.basho.com/riak/1.3.0/tutorials/installation/Installing-Erlang/#Install-using-kerl)
ADD ./vendor/kerl /tmp/kerl

# Install packages and perform cleanup
RUN set -x \
	&& buildDeps=' \
	    curl \
        git-core \
        build-essential \
        automake \
        libssl-dev \
        zlib1g-dev \
        libexpat-dev \
        libyaml-dev \
        libsqlite3-dev \
        libncurses5-dev \
        unixodbc-dev \
	' \
	&& requiredAptPackages=' \
	    openssl \
        fop \
        xsltproc \
	    locales \
        python2.7 \
        python-jinja2 \
        ca-certificates \
        libyaml-0-2 \
	' \
	&& echo 'deb http://packages.erlang-solutions.com/debian jessie contrib' >> \
        /etc/apt/sources.list \
    && apt-key adv \
        --keyserver keys.gnupg.net \
        --recv-keys 434975BD900CCBE4F7EE1B1ED208507CA14F4FCA \
	&& apt-get update \
	&& apt-get install -y $buildDeps $requiredAptPackages --no-install-recommends \
	&& dpkg-reconfigure locales && \
        locale-gen C.UTF-8 \
    && /usr/sbin/update-locale LANG=C.UTF-8 \
    && echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen \
    && locale-gen \
    && cd /tmp \
    && ./kerl build $ERLANG_VERSION erlversion \
    && ./kerl install erlversion /opt/erlang \
    && . /opt/erlang/activate \
    && ./kerl delete build erlversion \
    && ./kerl cleanup all \
    && erl -version \
    && git clone https://github.com/processone/ejabberd.git \
        --branch $EJABBERD_BRANCH --single-branch --depth=1 \
    && cd ejabberd \
    && chmod +x ./autogen.sh \
    && ./autogen.sh \
    && ./configure --enable-user=$EJABBERD_USER \
        --enable-all \
        --disable-tools \
        --disable-pam \
    && make \
    && make install \
    && mkdir $EJABBERD_HOME/ssl \
    && mkdir $EJABBERD_HOME/conf \
    && mkdir $EJABBERD_HOME/database \
    && cd $EJABBERD_HOME \
    && rm -rf /tmp/ejabberd \
    && rm -rf /etc/ejabberd \
    && ln -sf $EJABBERD_HOME/conf /etc/ejabberd \
    && chown -R $EJABBERD_USER: $EJABBERD_HOME \
    && rm -rf /var/lib/apt/lists/* \
	&& apt-get purge -y --auto-remove $buildDeps \
	&& apt-get clean

# Wrapper for setting config on disk from environment
# allows setting things like XMPP domain at runtime
ADD ./run.sh /sbin/run

# Add run scripts
ADD ./scripts $EJABBERD_HOME/scripts

# Add config templates
ADD ./conf /opt/ejabberd/conf

# Continue as user
USER $EJABBERD_USER

# Set workdir to ejabberd root
WORKDIR $EJABBERD_HOME

VOLUME ["$EJABBERD_HOME/database", "$EJABBERD_HOME/ssl"]
EXPOSE 4560 5222 5269 5280

CMD ["start"]
ENTRYPOINT ["run"]
