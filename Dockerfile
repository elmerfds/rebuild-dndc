FROM alpine:3.10
LABEL MAINTAINER="eafxx"

# Prerequisites
RUN apk add --update docker docker-compose openrc bash curl libxml2-utils jq tzdata && \ 
    rc-update add docker boot && \
    mkdir -p /app/pf

# Setting environment variables
ENV app_dir="/app/Rebuild-DNDC" \
    rundockertemplate_script="/app/Rebuild-DNDC/ParseDockerTemplate.sh" \
    mastercontepfile_loc="/config/rebuild-dndc" \
    rdndc_logo="https://raw.githubusercontent.com/elmerfdz/unRAIDscripts/master/Rebuild-DNDC/img/rdndc-logo.png" \
    discord_username="Rebuild-DNDC" \
    pf_loc=/app/pf \
    TZ=

# Add local files
COPY Rebuild-DNDC/ /app/Rebuild-DNDC
COPY root/ /

WORKDIR /app/Rebuild-DNDC   
CMD sh /etc/cont-init.d/30-install