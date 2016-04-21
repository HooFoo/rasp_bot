#!/usr/bin/env bash
if ! type 'ruby' > /dev/null; then
    gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    \curl -sSL https://get.rvm.io | bash -s stable --ruby=2.2.3
fi
if ! type 'bundle' > /dev/null; then
    gem install bundler
fi
bundle install
bundle exec ruby application.rb &
echo $1 > bot.pid
tail -f this_month.log