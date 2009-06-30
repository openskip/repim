export GEMNAME="openskip-repim"
rm -rf ./pkg && rake package && gem install pkg/${GEMNAME} --no-rdoc --no-ri && gem clean ${GEMNAME}

