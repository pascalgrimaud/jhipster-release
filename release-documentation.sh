#!/bin/bash

JHIPSTER_HOME=/home/pgrimaud/projects/jhipster/
tag=v6.1.0

##################################################
# Check
##################################################

# Check if the jhipster.github.io has been cloned
# TODO

# Check if the documentation-archive has been cloned
# TODO

##################################################
# Start the release process
##################################################

echo "*** delete old folder: tmp/documentation-archive"
rm -rf tmp/documentation-archive/

echo "*** recreate folder: tmp/documentation-archive"
mkdir -p tmp/documentation-archive/$tag

echo "*** start docker-compose"
docker-compose -f documentation-archive.yml up -d

echo "*** wait 20sec"
sleep 20

echo "*** go into $JHIPSTER_HOME/jhipster.github.io/"
cd $JHIPSTER_HOME/jhipster.github.io/

echo "*** switch to tag version: $tag"
git checkout $tag

echo "*** create _config-baseurl.yml"
cat >  _config-baseurl.yml << EOF
baseurl: /documentation-archive/$tag
url: /documentation-archive/$tag
EOF

echo "*** create Gemfile"
rm Gemfile
echo "source 'https://rubygems.org'" > Gemfile
echo "gem 'github-pages'">>Gemfile

docker exec -w /srv/jekyll -it release-jhipster.tech bundle install
docker exec -w /srv/jekyll -it release-jhipster.tech bundle exec jekyll build -d /tmp/documentation-archive/$tag --config _config.yml,_config-baseurl.yml

echo "*** switch back to master branch"
git checkout master
git checkout -- .
git clean -fd

echo "*** go into $JHIPSTER_HOME/jhipster-release/"
cd $JHIPSTER_HOME/jhipster-release/

echo "*** create alert-snippet.html"
echo "<script>" > alert-snippet.html
echo "\$(document.body).prepend('<div class=\"alert alert-danger alert-dismissible fade in\" style=\"z-index: 9999;padding-top: 80px;height: 80;margin:0px;top:0;\" role=\"alert\"><h4><i class=\"fa fa-exclamation-triangle\"><\/i> JHipster old documentation<\/h4><p>This documentation is for an older version of JHipster. Click <a href=\"https://jhipster.github.io/\">here</a> for the current version of the documentation.<\/p><\/div>');</script>" >> alert-snippet.html

find tmp/documentation-archive/$tag -name "*.html" -exec sh -c "cat alert-snippet.html >> {}" \;
find tmp/documentation-archive/$tag -name "*.html" -exec sh -c "sed -i '/<\/head>/i     <meta name=\"robots\" content=\"noindex\">' {}" \;

echo "*** stop docker-compose for release"
docker-compose -f documentation-archive.yml down

echo "*** copy the documentation archive"
cp -R tmp/documentation-archive/$tag $JHIPSTER_HOME/documentation-archive/

# TODO
# Add the new release to the index.html

# back to local folder
cd ../jhipster-release/

##################################################
# Instructions to publish the release
##################################################
