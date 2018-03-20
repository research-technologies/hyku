FROM ruby:2.3.1
RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev nodejs libreoffice imagemagick unzip ghostscript && \
    rm -rf /var/lib/apt/lists/*
RUN mkdir -p /opt/fits && \
    curl -fSL -o /opt/fits-1.0.5.zip http://projects.iq.harvard.edu/files/fits/files/fits-1.0.5.zip && \
    cd /opt && unzip fits-1.0.5.zip && chmod +X fits-1.0.5/fits.sh

RUN apt-get update -qq && apt-get install -y supervisor python-pip python-dev

RUN mkdir /data
WORKDIR /data

ADD Gemfile /data/Gemfile
ADD Gemfile.lock /data/Gemfile.lock
RUN bundle install

ADD requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

EXPOSE 3000
