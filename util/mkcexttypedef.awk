#!/usr/bin/awk

BEGIN {
  typname = "[ 	(*]" ARGV[2] "[ 	);]";
  tdstart = "[ 	]*typedef";
  isfuncpat = "typedef.*[ 	*]*" ARGV[2] "[ 	)]*[(]";
  isfuncpat2 = "typedef.*[ 	*]*" ARGV[2] "[ 	)]*$";
  semipat = "[ 	*]" ARGV[2] "[ 	]*;$";
  delete ARGV[2];
  ins = 0;
  havestart = 0;
  havename = 0;
  isfunc = 0;
  doend = 0;
  acount = 0;
  sarr[0] = "";
#print "tdstart:" tdstart;
#print "typname:" typname;
#print "isfuncpat:" isfuncpat;
#print "semipat:" semipat;
}

{
  if ($0 ~ /^#/) {
    next;
  } else if (ins == 0 && $0 ~ tdstart) {
#print "start: " $0;
    ins = 1;
    havename = 0;
    isfunc = 0;
    acount = 0;
    sarr[acount] = $0;
    acount = acount + 1;
    havestart = 1;
    if ($0 ~ typname) {
#print "found name";
      havename = 1;
      if ($0 ~ isfuncpat || $0 ~ isfuncpat2) {
#print "is func";
        isfunc = 1;
      }
    }
    if ($0 ~ /;$/) {
#print "semi";
      if ($0 ~ semipat || isfunc) {
#print "semi ok";
        if (havename) {
#print "name";
          doend = 1;
        }
      }
      ins = 0;
      havestart = 0;
    }
  } else if (ins == 1) {
#print "1: " $0;
    sarr[acount] = $0;
    acount = acount + 1;
    if ($0 ~ typname) {
#print "found name";
      havename = 1;
      if ($0 ~ isfuncpat) {
#print "is func";
        isfunc = 1;
      }
    }
    if ($0 ~ /;$/) {
#print "semi";
      if ($0 ~ semipat || isfunc) {
#print "semi ok";
        if (havename) {
#print "name";
          doend = 1;
        }
      }
      ins = 0;
      havestart = 0;
    }
  }

  if (doend == 1) {
    for (i = 0; i < acount; ++i) {
      print sarr[i];
    }
    exit;
  }
}
