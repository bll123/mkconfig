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

ver=$(cat VERSION)
if [[ $ver != "" ]] ; then
  cp -pf web/index.html web/rindex.html
  sed -i -e "s/#VERSION#/${ver}/g" web/index.html

  for f in man/*.7; do
    groff -man -Thtml $f > web/$(basename -s.7 $f).html
  done

  rsync -e "$ssh" -aSv \
      web/*.html ${remuser}@${server}:${wwwpath}
  mv -f web/rindex.html web/index.html
fi

for f in man/*.7; do
  fn=web/$(basename -s.7 $f).html
  test -f $fn && rm -f $fn
done

exit 0
