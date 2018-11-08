FROM debian:9-slim
LABEL maintainer="Alexey Sudachen <alexey@sudachen.name>"

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update --fix-missing \
    && apt-get install -qy --no-install-recommends \
	ca-certificates \
	wget \
        git \	
        bash \
        sudo \
	unzip \
	bzip2 \
        tzdata \
	locales \
	libsm6 \
	libxt6 \
	libxrender1 \
	procps \
	openssh-server \
	ssh \
	nginx \
        cron \
	openvpn \
        net-tools \
        iputils-ping \
        dnsutils \
        \
    && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 en_US.UTF-8

ENV CONDA_VERSION=4.2.12 \
    TINI_VERSION=0.16.1 \
    CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=jupyter \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    PATH=/opt/conda/bin:$PATH \
    HOME=/home/jupyter \
    TZ=America/Santiago

ADD fix-permissions /usr/local/bin/fix-permissions
RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && echo ${TZ} > /etc/timezone \
    && chmod a+x /usr/local/bin/fix-permissions \
    && useradd -m -s ${SHELL} -N -u ${NB_UID} ${NB_USER} \
    && mkdir -p ${CONDA_DIR} \
    && chown ${NB_USER}:${NB_GID} ${CONDA_DIR} \
    && chmod g+w /etc/passwd /etc/group \
    && fix-permissions ${HOME} \
    && fix-permissions ${CONDA_DIR}

USER $NB_UID

RUN mkdir ${HOME}/work \
    && wget https://repo.continuum.io/miniconda/Miniconda3-${CONDA_VERSION}-Linux-x86_64.sh -O ${HOME}/miniconda.sh \
    && ${SHELL} ${HOME}/miniconda.sh -f -b -p ${CONDA_DIR} \
    && rm ${HOME}/miniconda.sh \
    && conda config --system --prepend channels conda-forge \
    && conda config --system --set auto_update_conda false \
    && conda config --system --set show_channel_urls true \
    && conda install -y 'pip=10.*' 'python=3.6' \
    && conda update --all -y \
    && conda clean -tipsy \
    && rm -rf ${HOME}/.cache/yarn \
    && echo ". ${CONDA_DIR}/etc/profile.d/conda.sh" >> ${HOME}/.bashrc \
    && echo "conda activate base" >> ${HOME}/.bashrc 

RUN echo $(date)
RUN conda install -y \
       'blas=1.1=*openblas*' \
       'numpy=1.14.*=*openblas*' \
    && conda clean -tipsy 

RUN conda install -y \
       'cython=0.28*' \
       'pandas=0.23*' \
       'psycopg2=2.7.*' \
       'pymysql=0.8.*' \
       'sqlalchemy=1.2.8' \
	pexpect \
        numba \
    && conda clean -tipsy 

#RUN conda install -y \
#        numba -c numba \
#    && conda clean -tipsy 

RUN conda install -y \
        gunicorn \
        scrapy \        
    	psutil \
    && conda clean -tipsy 

RUN conda install -y \
	-c carta python3-saml \
    && conda clean -tipsy 

RUN pip install -U --no-cache-dir \
    	pyotp \
        pyyaml \
	'google-api-python-client>=1.6' \
	'oauth2client>=4.1' \
	'requests>=2.18' \
	'urllib3>=1.22' \
	singleton_decorator \
	pytz \
	circus \
    \
    && conda clean -tipsy 


USER root

RUN bash -c "for i in {1..9}; do mkdir -p /usr/share/man/man\$i; done" \
    && mkdir /var/run/sshd \
    && chmod 0755 /var/run/sshd

ADD circus.ini /etc/
CMD ["circusd", "/etc/circus.ini"]

RUN echo "jupyter ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/jupyter \ 
    && fix-permissions ${CONDA_DIR} \
    && fix-permissions ${HOME} \
    && echo PATH=$PATH > /etc/environment \
    && echo SHELL=$SHELL >> /etc/environment

RUN apt-get update --fix-missing \
    && apt-get install -qy --no-install-recommends \
        mysql-client \
        mysql-utilities \
        postgresql-client \
	nano \
        \
    && rm -rf /var/lib/apt/lists/* 


