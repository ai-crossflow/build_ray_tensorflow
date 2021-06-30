FROM ubuntu:bionic

ENV BAZEL_VERSION 4.1.0
ENV RAY_VERSION 1.4.0

RUN apt-get -qq update && apt-get -qq -y install curl wget gnupg git build-essential unzip psmisc \
    && curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > bazel.gpg \
    && mv bazel.gpg /etc/apt/trusted.gpg.d/
    
RUN curl -fsSL https://deb.nodesource.com/setup_12.x | bash - \
    && apt-get -qq update \
    && apt-get -qq -y install nodejs
    
RUN if [ "$(uname -m)" = "aarch64" ]; then \
        echo "deb [arch=arm64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list ; \
    else \
        echo "deb [arch=amd64] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list ; \
    fi \
    && apt-get -qq update \
    && apt-get -qq -y install bazel
RUN curl -sSL  https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-$(uname -m).sh -o /tmp/miniforge.sh \
    && bash /tmp/miniforge.sh -bfp /usr/local \
    && rm -rf /tmp/miniforge.sh \
    && conda install -y python=3.8 \
    && conda update conda \
    && apt-get -qq -y remove curl bzip2 \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes

RUN bazel version

# build ray
RUN conda install -y jupyterlab cython=0.29 grpcio protobuf scipy aiohttp gpustat jsonschema msgpack-python pydantic pyyaml psutil \
                     blessings multidict yarl \
                     aioredis click opencensus filelock aiohttp-cors
RUN pip install redis py-spy colorama


RUN git clone -b ray-${RAY_VERSION} --depth 1 https://github.com/ray-project/ray.git
RUN cd ray && bazel build //:ray_pkg
RUN cd ray && bazel build //:cpp:ray_cpp_pkg
RUN cd ray && bazel build //:java:ray_java_pkg
RUN cd ray/dashboard/client \
    && npm install \
    && npm run build \
    && cd ../../.. \
    && cd ray/python \
    && pip install -e .
    
CMD  ["/bin/sh"]
