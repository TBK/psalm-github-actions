FROM php:7.3-alpine

LABEL "com.github.actions.name"="Psalm"
LABEL "com.github.actions.description"="Static analysis tool for finding errors in PHP applications"
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="http://github.com/tbk/psalm-github-actions"
LABEL "homepage"="http://github.com/actions"
LABEL "maintainer"="TBK <tbk@jjtc.eu>"


# DIRTY JOB - Install extra extension
# official php image should provide a better mechanism to install extensions,
# one command to do it all - pulling in the correct build dependencies, compile, enable & cleanup
RUN apk add --no-cache libpng tidyhtml libldap libpng-dev tidyhtml-dev openldap-dev \
    && docker-php-ext-install gd tidy ldap pdo_mysql \
    && docker-php-ext-enable gd tidy ldap pdo_mysql \
    && apk del libpng-dev tidyhtml-dev openldap-dev

# Code borrowed from mickaelandrieu/psalm-ga which in turn borrowed from phpqa/psalm

# Install Tini - https://github.com/krallin/tini
RUN apk add --no-cache tini git

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME="/composer" \
    composer global config minimum-stability dev

# This line invalidates cache when master branch change
ADD https://github.com/vimeo/psalm/commits/master.atom /dev/null

RUN COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_HOME="/composer" \
    composer global require vimeo/psalm --prefer-dist --no-progress --dev

ENV PATH /composer/vendor/bin:${PATH}

# Satisfy Psalm's quest for a composer autoloader (with a symlink that disappears once a volume is mounted at /app)
RUN mkdir /app && ln -s /composer/vendor/ /app/vendor

# Add entrypoint script
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Package container
WORKDIR "/app"
ENTRYPOINT ["/entrypoint.sh"]
