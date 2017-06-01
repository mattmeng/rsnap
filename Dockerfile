FROM ruby:2-alpine

WORKDIR /root

RUN apk update
RUN apk add rsync

ADD Gemfile .
RUN bundle install

ADD schedule ./
RUN crontab schedule

ADD rsnap.rb backup.rb ./

CMD ["crond", "-f", "-l", "0"]
