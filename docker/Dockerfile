ARG TIMEZONE="Asia/Tokyo"

FROM ubuntu:18.04

ENV TZ=${TIMEZONE}
ENV DEBIAN_FRONTEND=noninteractive

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone

RUN apt-get update && apt-get -y upgrade && apt-get install -y \
    build-essential git blender bc cython3 \
    python3-numpy python3-matplotlib python3-opencv python3-tqdm python3-skimage \
    python3-setuptools

RUN git clone https://github.com/ishitsuka-hikaru/video-classification-simulator.git
RUN git clone https://github.com/ishitsuka-hikaru/mogen.git
RUN git clone -b makehuman https://github.com/ishitsuka-hikaru/3D-ResNets-PyTorch.git
RUN git clone https://bitbucket.org/Diffeomorphic/makewalk.git
RUN git clone https://github.com/makehumancommunity/mhx2-makehuman-exchange.git && \
    cd /mhx2-makehuman-exchange && \
    git checkout 72fcc5ddcf6b71f725938a21f7096076e9b464c
RUN cd /usr/share/blender/scripts/addons && \
    ln -s /makewalk/ makewalk && \
    ln -s /mhx2-makehuman-exchange/import_runtime_mhx2/ import_runtime_mhx2
RUN git clone https://github.com/ishitsuka-hikaru/data-augmentation-for-coco.git
RUN git clone https://github.com/cocodataset/cocoapi.git && \
    cd /cocoapi/PythonAPI && \
    python3 setup.py build_ext install
