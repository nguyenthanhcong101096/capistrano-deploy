![](https://lh3.googleusercontent.com/proxy/kNbp0STR_daiJ9QN6J7HPLaCTH94gs0tbrKzHb9mRLu03uOi6k4yQp0dJg1dJihvkge1Q-9RWrPUHvQNDG96JOd72Jg_mivRnreVOT9PeATy_QCp5JRfIN1NBw)
# Deploy app with Capistrano
[Capistrano](https://capistranorb.com/documentation/getting-started/local-tasks/) | [Github](https://github.com/capistrano/capistrano)

### Step 1: Add gem && bundle install
* **Gemfile**

```
group :development
  gem 'capistrano', '~> 3.6.0', require: false
  gem 'capistrano-rails', '~> 1.1', require: false
  gem 'capistrano-rbenv'
  gem 'capistrano-bundler', '~> 1.2', require: false
  gem 'capistrano3-puma', require: false
  gem 'capistrano-sidekiq', require: false
  gem 'capistrano-yarn', require: false
end
```

`bundle install`

* Make sure your project doesn't already have a "Capfile" or "capfile" present. Then run:

`bundle exec cap install`

* To customize the stages that are created, use:

`bundle exec cap install STAGES=local,sandbox,qa,production`

#### Step 2: Config Capfile & deploy.rb staging.rb
* **Capfile**

```
require 'capistrano/setup'
require 'capistrano/deploy'

require 'capistrano/rbenv'
require 'capistrano/bundler'
# require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'
require 'capistrano/puma'
require 'capistrano/sidekiq'
require 'seed-fu/capistrano3'

Dir.glob('lib/capistrano/tasks/*.rake').each { |r| import r }
```

* **Deploy.rb**

```
# config valid only for current version of Capistrano
lock '3.6.1'

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :airbrussh.
set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
set :pty, false

# Default value for :linked_files is []
set :linked_files, ['config/database.yml', 'config/master.key', ".env.#{fetch(:stage)}"]

# Default value for linked_dirs is []
set :linked_dirs, ['log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'bundle', 'public/packs', 'config/puma', 'node_modules', 'public/uploads']
# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3
set :local_user, 'congnt'
set :use_sudo, false

namespace :yarn do
  desc 'Run rake yarn install'
  task :install do
    on roles(:web) do
      within release_path do
        execute("cd #{release_path} && yarn install")
      end
    end
  end
end

namespace :assets do
  desc 'Precompile assets locally and then rsync to deploy server'
  task :precompile do
    on roles(:all) do
      run_locally do
        execute "RAILS_ENV=#{fetch(:stage)} bundle exec rails assets:precompile"
        execute "rsync -av ./public/packs/ #{fetch(:user)}@#{fetch(:server)}:#{current_path}/public/packs/"
        execute 'rm -rf public/packs'
      end
    end
  end
end

namespace :deploy do
  desc 'Upload yml file.'
  task :upload_yml do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      execute "mkdir -p #{shared_path}/config/puma"
      upload!('package.json', "#{shared_path}/package.json")
      upload!("config/puma/#{fetch(:stage)}.rb", "#{shared_path}/config/puma/#{fetch(:stage)}.rb")
      upload!(".env.#{fetch(:stage)}", "#{shared_path}/.env.#{fetch(:stage)}")
      upload!('config/database.yml', "#{shared_path}/config/database.yml")
      upload!('config/master.key', "#{shared_path}/config/master.key")
    end
  end
end

namespace :db do
  desc 'Seed the database.'
  task :seed do
    on roles(:app) do
      within current_path do
        with(rails_env: fetch(:stage)) do
          execute :bundle, :exec, :rake, 'db:seed_fu'
        end
      end
    end
  end

  desc 'Reset database'
  task :reset do
    on roles(:app) do
      within current_path do
        with(rails_env: fetch(:stage)) do
          execute :bundle, :exec, :rake, 'db:drop db:create db:migrate'
        end
      end
    end
  end
end

task :log do
  on roles(:app) do
    execute "cd #{shared_path}/log && tail -f #{fetch(:stage)}.log"
  end
end

before('deploy', 'puma:stop')
after('deploy:updated', 'assets:precompile')

```

### Step 3: Create instace EC2 in AWS
* Set group security with ssh port **22** and http port **80**
* Before create you should download file **your-instance.pem**

```
chmod 400 your-instance.pem
ssh -i path/to/your-instance.pem ubuntu@your-public-dns
```
### Step 4: Update OS

`sudo apt-get update && sudo apt-get -y -upgrade `

* Create a new user & set password in ubuntu server

```
sudo useradd -d /home/deploy -m deploy
sudo passwd deploy
```

### Step 5: Run sudo visudo command in server
`sudo visudo`

* chỉnh phân quyền cho user deploy **deploy ALL=(ALL:ALL)ALL**

### Step 6: Login as deploy user and create public key

```
sudo su -deploy
ssh-keygen
```

### Step 7: Copy id_rsa.pub and and copy to github ssh
* Trên server trong thư mục **~/.ssh**
* copy tới github để có quyền

`cat id_rsa.pu`

### Step 8: Copy your local machine public key and paste in server authorized_keys
* Trên máy local

```
ssh-keygen -t rsa -C <local-name>
cd ~/.ssh
ssh-add ~/.ssh/id_rsa
cat id_rsa.pub
```

* Copy id_rsa bỏ trong **authorized_keys** trong **~/.ssh** trên server

```
cd ~/.ssh
nano authorized_keys
```

### Step 9: Nginx in server

```
sudo apt-get install git
sudo apt-get install nginx
```

* Edit your nginx config file

```
sudo rm /etc/nginx/sites_enabled/default
sudo nano /etc/nginx/conf.d/default.conf
```

**Nginx file**

```
upstream app {
   server unix:/home/deploy/nguoimexe/shared/tmp/sockets/puma.sock fail_timeout=0;
}

server {
  listen     80;
  listen     443;

  ssl        on;
  ssl_certificate /etc/nginx/ssl/cert.pem;
  ssl_certificate_key /etc/nginx/ssl/key.pem;

  server_name www.nguoimexe.com;

  root /home/deploy/nguoimexe/current/public;

  try_files $uri/index.html $uri @app;

  location ~* \.(js|css|png|jpg|jpeg|gif|ico|wmv|3gp|avi|mpg|mpeg|mp4|flv|mp3|mid|wml|swf|pdf|doc|docx|ppt|pptx|zip)$ {
    expires 5d;
    access_log off;
  }

  location / {
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header Host $host;
    proxy_redirect off;
    proxy_http_version 1.1;
    proxy_set_header Connection '';
    proxy_pass http://app;
  }

 location /cable {
   proxy_pass http://app;
   proxy_http_version 1.1;
   proxy_set_header Upgrade $http_upgrade;
   proxy_set_header Connection "Upgrade";

   proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
   proxy_set_header Host $http_host;
   proxy_set_header X-Real-IP $remote_addr;
   proxy_set_header X-Forwarded-Proto https;
   proxy_redirect off;
 }


  client_max_body_size 4G;
  keepalive_timeout 10;
}
```

### Step 10: Postgres Install
* Install postgres

`sudo apt-get install postgresql postgresql-contrib libpq-dev`

* Create user in postgres

`sudo -u postgres createuser -s "user-name-data"`

* Set password

```
sudo -u postgres psql
\password "user-name-data"
```

* Creata database

`sudo -u postgres createdb -O "user-name-data" "database-name"`

### Step 11: Install rbenv && ruby
### Step 12: Create project folder, database.yml, application.yml, master.key

```
pwd
mkdir project_app
ls
mkdir - p project_app/shared/config
```

* Database

`nano project_app/shared/config/database.yml`

**database.yml**

```

production:
  adapter: postgresql
  encoding: unicode
  database: database_production
  username: your-name
  password: your-password
  host: localhost
  port: 5432
```

**application.yml**

* generate serect_key and copy to application.yml in server
* thư mục project run RAILS_ENV=production rake secret SECRET_KEY_BASE: "<your_secret_key_base>"

`nano project_app/shared/config/application.yml`

**Rails > 5.2**

`application.yml -> master.key`

#### REST NGINX

`apt-get purge nginx*`
