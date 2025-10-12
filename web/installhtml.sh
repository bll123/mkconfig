#!/bin/bash
#
# requirements: groff
#

tserver=web.sourceforge.net
echo -n "Server [$tserver]: "
read server
if [[ $server == "" ]]; then
  server=$tserver
fi

tremuser=bll123
echo -n "User [$tremuser]: "
read remuser
if [[ $remuser == "" ]]; then
  remuser=$tremuser
fi

case $server in
  web.sourceforge.net)
    port=22
    project=mkconfig
    # ${remuser}@web.sourceforge.net:/home/project-web/${project}/htdocs
    wwwpath=/home/project-web/${project}/htdocs
    ;;
esac
ssh="ssh -p $port"
export ssh

TMP=web/htdocs
test -d $TMP && rm -rf $TMP
mkdir $TMP

ver=$(cat VERSION)
if [[ $ver != "" ]] ; then
  sed -e "s/#VERSION#/${ver}/g" web/index.html > $TMP/index.html

  for f in man/*.7; do
    groff -man -Thtml $f > $TMP/$(basename -s.7 $f).html
  done

  rsync -e "$ssh" -aSv --delete \
      $TMP/ ${remuser}@${server}:${wwwpath}
fi

rm -rf $TMP

exit 0
