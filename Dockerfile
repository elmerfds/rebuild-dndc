FROM hotio/base:latest
LABEL MAINTAINER="eafxx"

# Prerequisites
RUN apt update && \
    apt install -y install apt-transport-https ca-certificates curl software-properties-common &&\
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - && \ 
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" && \ 
    apt update && \
    apt-cache policy docker-ce && \
    apt install docker-ce  && \
    mkdir -p /app/pf

# Setting environment variables
ENV app_dir="/app/Rebuild-DNDC" \
    rundockertemplate_script="/app/Rebuild-DNDC/ParseDockerTemplate.sh" \
    docker_tmpl_loc="/config/docker-templates" \
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