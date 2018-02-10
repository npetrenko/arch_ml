FROM base/archlinux

# A docker container with the Nvidia kernel module and CUDA drivers installed

# driver for my aws installation:
ENV CUDA_RUN https://developer.nvidia.com/compute/cuda/8.0/prod/local_installers/cuda_8.0.44_linux-run

#ENV CUDA_RUN https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run

RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen && locale-gen && echo LANG=en_US.UTF-8 > /etc/locale.conf

ENV LC_ALL en_US.UTF-8

RUN pacman -Sy && pacman -S --noconfirm \
  wget \
  module-init-tools \
  base-devel cmake vim openssh git

RUN cd /opt && mkdir nvidia_installers && cd nvidia_installers && \
  wget $CUDA_RUN && \
  chmod +x cuda_8.0.* && \
  mkdir nvidia_installers && \
  ./cuda_8.0.* --tar xmvf && \
  ./cuda_8.0.* -extract=/tmp/nvidia_installers

WORKDIR /opt/nvidia_installers

#RUN  mkdir /usr/share/perl5/vendor_perl && \
RUN cp InstallUtils.pm /usr/share/perl5/vendor_perl

WORKDIR /tmp/nvidia_installers

RUN ./NVIDIA-Linux-x86_64-*.run -s -N --no-kernel-module && \
    ./cuda-linux64-rel-8.0*.run -noprompt

# Ensure the CUDA libs and binaries are in the correct environment variables
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/cuda-8.0/lib64
ENV PATH=$PATH:/usr/local/cuda-8.0/bin

RUN ./cuda-samples-linux-8.0*.run -noprompt -cudaprefix=/usr/local/cuda-8.0 &&\
    cd /usr/local/cuda/samples/1_Utilities/deviceQuery &&\ 
    make

WORKDIR /tmp/cudnn

# cudnn arhiv has to be in the dockerfile dir
ADD cudnn* ./

RUN mv cuda/include/* /usr/local/cuda/include && mv cuda/lib64/* /usr/local/cuda/lib64 && \
    ldconfig /usr/local/cuda/lib64

RUN rm -R /opt/nvidia_installers /tmp/nvidia_installers

WORKDIR /root
