ARG TIMEZONE="Asia/Tokyo"

FROM ubuntu:18.04

ENV TZ=${TIMEZONE}
ENV DEBIAN_FRONTEND=noninteractive

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

RUN apt update && apt -y upgrade && apt install -y \
    build-essential git python3-numpy blender

RUN git clone https://github.com/ishitsuka-hikaru/video-classification-simulator.git /vcs
RUN git clone https://github.com/ishitsuka-hikaru/mogen.git /mogen
RUN git clone https://bitbucket.org/Diffeomorphic/makewalk.git /makewalk
RUN git clone https://github.com/makehumancommunity/mhx2-makehuman-exchange.git /mhx2
RUN cd /usr/share/blender/scripts/addons &&
    ln -s /makewalk/ makewalk &&
    ln -s /mhx2/import_runtime_mhx2/ import_runtime_mhx2
    