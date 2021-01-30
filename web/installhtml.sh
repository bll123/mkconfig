#!/bin/bash
#
# requirements: sshpass, groff
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

echo -n "Remote Password: "
read -s SSHPASS
echo ""
export SSHPASS


ver=$(cat ../VERSION)
if [[ $ver != "" ]] ; then
  cp -pf index.html rindex.html
  sed -i -e "s/#VERSION#/${ver}/g" index.html

  for f in ../man/*.7; do
    groff -man -Thtml $f > $(basename -s.7 $f).html
  done

  sshpass -e rsync -e "$ssh" -aSv \
      *.html ${remuser}@${server}:${wwwpath}
  mv -f rindex.html index.html
fi

for f in ../man/*.7; do
  fn=$(basename -s.7 $f).html
  test -f $fn && rm -f $fn
done

unset SSHPASS
exit 0
