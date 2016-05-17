# Procfile Configuration

# Procfile
web: bundle exec rails s -p $PORT

# format for Procfile
<process-type>: <command> # <--- simple format

# Procfile
web: bundle exec rails s -p $PORT
worker: bundle exec rake worker
urgentworker: bundle exec rake urgent_worker
scheduler: bundler exec rake scheduler

# Foreman is a cmd line tool for running proc file backed apps
$ gem install foreman

# all you have to do is go the your apps directory
$ foreman start
