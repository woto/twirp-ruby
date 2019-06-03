FROM ruby:stretch

RUN apt-get update

# Install protoc
RUN apt-get install -y autoconf automake libtool curl make g++ unzip
RUN wget https://github.com/protocolbuffers/protobuf/releases/download/v3.6.1/protobuf-all-3.6.1.zip
RUN unzip protobuf-all-3.6.1.zip
RUN ./protobuf-3.6.1/configure && make && make check && make install && ldconfig

# Install ruby protobuf generator
RUN gem install google-protobuf

# Install go
RUN apt-get install -y golang-go
ENV GOPATH /go
ENV PATH="${GOPATH}/bin:${PATH}"

# Copy ruby twirp generator files over and install
RUN mkdir -p /go/src/github.com/twitchtv/twirp-ruby
COPY Gopkg.* vendor/ protoc-gen-twirp_ruby/ internal/ /go/src/github.com/twitchtv/twirp-ruby/
COPY vendor /go/src/github.com/twitchtv/twirp-ruby/vendor/
COPY protoc-gen-twirp_ruby /go/src/github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby/
COPY  internal /go/src/github.com/twitchtv/twirp-ruby/internal/
RUN go install github.com/twitchtv/twirp-ruby/protoc-gen-twirp_ruby

# Copy ruby twirp gem files and install
COPY twirp.gemspec Gemfile* LICENSE README.md /go/src/github.com/twitchtv/twirp-ruby/
COPY lib /go/src/github.com/twitchtv/twirp-ruby/lib

# Generate test server/client
COPY test-generator /go/src/github.com/twitchtv/twirp-ruby/test-generator
WORKDIR /go/src/github.com/twitchtv/twirp-ruby/test-generator 
RUN gem build ../twirp.gemspec -o twirp.gem && gem install ../twirp.gem
RUN gem install bundler
RUN bundle install

CMD ["ruby", "test.rb"]
