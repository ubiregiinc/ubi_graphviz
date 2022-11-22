FROM ruby:3.0
WORKDIR /app
RUN bundle config set --global force_ruby_platform true
RUN gem i bundler
COPY . .
