FROM w201rdada/binder:82106ad
MAINTAINER "Brooks Ambrose" brooksambrose@berkeley.edu

USER root

RUN apt-get update \
&& apt-get install -y --no-install-recommends \
   software-properties-common \
   curl dos2unix dnsutils && \
   apt-get purge && \
   apt-get clean && \
   rm -rf /var/lib/apt/lists/*

# add hub from https://hub.github.com
RUN cd ~ && wget https://github.com/github/hub/releases/download/v2.2.9/hub-linux-amd64-2.2.9.tgz \
&& tar -zxvf hub-linux-amd64-2.2.9.tgz \
&& ./hub-linux-amd64-2.2.9/install \
&& rm -rf hub* \
&& hub version

RUN install2.r --repos "https://cloud.r-project.org" --deps TRUE \
	stargazer \
	httr \
	kableExtra \
	XML \
&& r -e 'warnings()'

# install R packages
RUN . /etc/environment \
&& r -e 'devtools::install_github(c("rstudio/bookdown","1beb/RGoogleDrive"))' \
&& r -e 'warnings()'

# add caddy web server
RUN curl https://getcaddy.com | bash -s personal

EXPOSE 80 443 2015

USER ${NB_USER}

# fun with line endings
RUN git config --global core.autocrlf input
