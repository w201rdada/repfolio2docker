FROM rocker/verse:3.4.2
MAINTAINER "Brooks Ambrose" brooksambrose@berkeley.edu

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
   software-properties-common \
   curl dos2unix dnsutils \
   apt-get purge && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/*

# add hub from https://hub.github.com
RUN cd ~ && wget https://github.com/github/hub/releases/download/v2.2.9/hub-linux-amd64-2.2.9.tgz \
&& tar -zxvf hub-linux-amd64-2.2.9.tgz \
&& ./hub-linux-amd64-2.2.9/install \
&& rm -rf hub* \
&& hub version

# install R packages
RUN . etc/environment \
&& r -e 'devtools::install_github(c("rstudio/bookdown","1beb/RGoogleDrive"))' \
&& r -e 'warnings()'

RUN . etc/environment \
&& install2.r --repos $MRAN --deps TRUE \
	stargazer \
	httr \
	kableExtra \
&& r -e 'warnings()'

# add caddy web server
RUN curl https://getcaddy.com | bash

# fun with line endings
RUN git config --global core.autocrlf input

EXPOSE 80 443 2015

ENV NB_USER rstudio
ENV NB_UID 1000
ENV VENV_DIR /srv/venv

# Set ENV for all programs...
ENV PATH ${VENV_DIR}/bin:$PATH
# And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron

# The `rsession` binary that is called by nbrsessionproxy to start R doesn't seem to start
# without this being explicitly set
ENV LD_LIBRARY_PATH /usr/local/lib/R/lib

ENV HOME /home/${NB_USER}
WORKDIR ${HOME}

RUN apt-get update && \
    apt-get -y install python3-venv python3-dev && \
    apt-get purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a venv dir owned by unprivileged user & set up notebook in it
# This allows non-root to install python libraries if required
RUN mkdir -p ${VENV_DIR} && chown -R ${NB_USER} ${VENV_DIR}

USER ${NB_USER}
RUN python3 -m venv ${VENV_DIR} && \
    pip3 install --no-cache-dir \
         notebook==5.2 \
         git+https://github.com/jupyterhub/nbrsessionproxy.git@6eefeac11cbe82432d026f41a3341525a22d6a0b \
         git+https://github.com/jupyterhub/nbserverproxy.git@5508a182b2144d29824652d8977b32302517c8bc && \
    jupyter serverextension enable --sys-prefix --py nbserverproxy && \
    jupyter serverextension enable --sys-prefix --py nbrsessionproxy && \
    jupyter nbextension install    --sys-prefix --py nbrsessionproxy && \
    jupyter nbextension enable     --sys-prefix --py nbrsessionproxy


RUN R --quiet -e "devtools::install_github('IRkernel/IRkernel')" && \
    R --quiet -e "IRkernel::installspec(prefix='${VENV_DIR}')"


CMD jupyter notebook --ip 0.0.0.0
