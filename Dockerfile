FROM ruby:3.4.2-alpine

RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    ruby-dev

RUN git clone --depth=1 https://github.com/vlang/v && cd v && make && ./v symlink

WORKDIR /app

COPY . .

RUN v install && v run build.vsh 

CMD ["./ChangedPatcher"]