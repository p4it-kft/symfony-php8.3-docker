FROM php:8.2

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"

#add nodejs package source
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash -

RUN apt-get update
RUN apt-get install -y git --no-install-recommends
RUN apt-get install -y nodejs --no-install-recommends
RUN apt-get install -y ssh --no-install-recommends

#cleanup apt
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#install yarn
RUN corepack enable

#install php extension installer
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

RUN apt-get install -y \
		file \
	;

RUN set -eux; \
	install-php-extensions \
		@composer \
		apcu \
		intl \
		opcache \
		zip \
		gd \
		xdebug \
	;

RUN apt-get update
RUN apt install -y \
		sudo \
		mc \
		bash-completion \
	;
RUN set -eux; \
	install-php-extensions \
    pdo pdo_mysql xsl exif mbstring \
    ;
#install symfony binary
RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

#add volume for app
VOLUME /app

#https://snyk.io/blog/10-best-practices-to-containerize-nodejs-web-applications-with-docker/
RUN apt-get update && apt-get install -y --no-install-recommends dumb-init
#set the default command
CMD ["dumb-init", "symfony", "serve"]

#expose port for smyfony serve
EXPOSE 8000

#add user for symfony binary
RUN addgroup --gid 1000 symfony
RUN adduser --uid 1000 --gid 1000 symfony
RUN adduser symfony sudo
RUN adduser symfony root

RUN echo 'symfony ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

#switch to symfony user
USER symfony:symfony

RUN echo 'eval "$(/app/bin/console completion )"' >> ~/.bashrc;

#set workdir for app
WORKDIR /app
