FROM debian:buster-backports

LABEL maintainer="Sebastien Delafond <sdelafond@gmail.com>"

ARG REPOSITORY=buster

USER root
ENV DEBIAN_FRONTEND=noninteractive

RUN echo 'APT::Install-Recommends "false";' > /etc/apt/apt.conf.d/no-recommends && \
    echo 'APT::Install-Suggests "false";' >> /etc/apt/apt.conf.d/no-recommends

RUN apt update -q

RUN apt install --yes aptly
RUN apt install --yes curl
RUN apt install --yes inoticoming
RUN apt install --yes jq

# base dir & volumes
ENV REPO_BASE_DIR=/opt/repository
ENV BIN_DIR=bin
ENV CONF_DIR=conf
ENV DB_DIR=db
ENV INCOMING_DIR=incoming
ENV POOL_DIR=pool
ENV WWW_DIR=www

RUN mkdir -p ${REPO_BASE_DIR}/${BIN_DIR}
RUN mkdir -p ${REPO_BASE_DIR}/${CONF_DIR}

RUN mkdir -p ${REPO_BASE_DIR}/${DB_DIR}
RUN mkdir -p ${REPO_BASE_DIR}/${INCOMING_DIR}
RUN mkdir -p ${REPO_BASE_DIR}/${POOL_DIR}
RUN mkdir -p ${REPO_BASE_DIR}/${WWW_DIR}

VOLUME ${REPO_BASE_DIR}/${DB_DIR}
VOLUME ${REPO_BASE_DIR}/${INCOMING_DIR}
VOLUME ${REPO_BASE_DIR}/${POOL_DIR}
VOLUME ${REPO_BASE_DIR}/${WWW_DIR}

WORKDIR ${REPO_BASE_DIR}

# copy required files
COPY .env .
COPY ${CONF_DIR}/* ${CONF_DIR}/
COPY ${BIN_DIR}/* ${BIN_DIR}/

CMD inoticoming --foreground ./${INCOMING_DIR}/${REPOSITORY} --suffix .changes ./${BIN_DIR}/incoming.sh ${REPOSITORY} {} \;
