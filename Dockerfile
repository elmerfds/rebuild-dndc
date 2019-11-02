FROM alpine:3.10
LABEL MAINTAINER="eafxx"

# Prerequisites
RUN apk add --update docker openrc bash curl libxml2-utils jq && \ 
    rc-update add docker boot && \
    mkdir /app

# Setting environment variables
ENV rundockertemplate_script="/app/Rebuild-DNDC/ParseDockerTemplate.sh" \
    docker_tmpl_loc="/config/docker-templates" \
    mastercontepfile_loc="/config/rebuild-dndc" \
    rdndc_logo="https://i.imgur.com/U6C54bW.png" \
    discord_username="Rebuild-DNDC" \
    discord_avatar="$rdndc_logo"

# Add local files
COPY Rebuild-DNDC/ /app/Rebuild-DNDC
COPY root/ /

WORKDIR /app/Rebuild-DNDC   
CMD sh /etc/cont-init.d/30-install