FROM base/archlinux

# A docker container with the Nvidia kernel module and CUDA drivers installed

ENV CUDA_RUN https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run

RUN pacman -Sy && pacman -S --noconfirm \
  wget \
  module-init-tools \
  base-devel

RUN cd /opt && mkdir nvidia_installers && cd nvidia_installers && \
  wget $CUDA_RUN && \
  chmod +x cuda_8.0.44_linux-run && \
  mkdir nvidia_installers && \
  ./cuda_8.0.44_linux-run --tar xmvf && \
  ./cuda_8.0.44_linux-run -extract=/tmp/nvidia_installers

WORKDIR /opt/nvidia_installers

RUN  mkdir /usr/share/perl5/vendor_perl && \
  cp InstallUtils.pm /usr/share/perl5/vendor_perl

WORKDIR /tmp/nvidia_installers

RUN ./NVIDIA-Linux-x86_64-367.48.run -s -N --no-kernel-module && \
    ./cuda-linux64-rel-8.0.44-21122537.run -noprompt

# Ensure the CUDA libs and binaries are in the correct environment variables
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-8.0/lib64
ENV PATH=$PATH:/usr/local/cuda-8.0/bin

RUN ./cuda-samples-linux-8.0.44-21122537.run -noprompt -cudaprefix=/usr/local/cuda-8.0 &&\
    cd /usr/local/cuda/samples/1_Utilities/deviceQuery &&\ 
    make

RUN rm -R /opt/nvidia_installers /tmp/nvidia_installers

#WORKDIR /usr/local/cuda/samples/1_Utilities/deviceQuery
WORKDIR /root

RUN useradd -m -G wheel user && \
    pacman -Syu --noconfirm && \
    pacman -Sc --noconfirm && \
    pacman -S --force --noconfirm vim python-pip opencv

ADD ./pyreqs.txt ./

RUN pip install -r pyreqs.txt && mkdir /tmp/cudnn

WORKDIR /tmp/cudnn

# cudnn arhiv has to be in the dockerfile dir
ADD cudnn* ./

RUN mv cuda/include/* /usr/local/cuda/include && mv cuda/lib64/* /usr/local/cuda/lib64 && \
    ldconfig /usr/local/cuda/lib64

WORKDIR /root

#remove tmp files and initialize pymystem
RUN rm -R /tmp/* && \
    printf 'from pymystem3 import Mystem\nstem=Mystem()' | python -
