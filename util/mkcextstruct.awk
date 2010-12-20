#!/usr/bin/awk

BEGIN {
  ststruct1 = "struct[	 ]*{"
  ststruct2 = "struct[	]*$"
  ststart = "struct[	 ]*" ARGV[2];
  stforward = "struct[	 ]*" ARGV[2] "[	 ]*;";
  stother = "struct[	 ]*" ARGV[2] "[	 ]*[*a-zA-Z_]";
  stend = ARGV[2] "_t";
  delete ARGV[2];
  bcount = 0;
  acount = 0;
  ins = 0;
  havestart = 0;
  doend = 0;
  sarr[0] = "";
#print "ststruct1:" ststruct1;
#print "ststruct2:" ststruct2;
#print "ststart:" ststart;
#print "stforward:" stforward;
#print "stother:" stother;
#print "stend:" stend;
}

{
#print "havestart:" havestart " ins:" ins " bcount:" bcount " acount:" acount;
#if ($0 ~ ststruct1) { print "matches ststruct1"; }
#if ($0 ~ ststruct2) { print "matches ststruct2"; }
#if ($0 ~ ststart) { print "matches ststart"; }
#if ($0 ~ stforward) { print "matches stforward"; }
#if ($0 ~ stother) { print "matches stother: " $0; }
  if ($0 ~ /^#/) {
    next;
  } else if (ins == 0 && $0 ~ ststart && $0 !~ stforward && $0 !~ stother) {
#print "start: " $0;
    ins = 1;
    acount = 0;
    sarr[acount] = $0;
    acount = acount + 1;
    havestart = 1;
    tstr = $0;
    gsub (/[^{]/, "", tstr);
    bcount = bcount + length (tstr);
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (bcount <= 0 && length (tstr) > 0) {
      doend = 1;
    }
  } else if (havestart == 0 && bcount == 0 &&
      ($0 ~ ststruct1 || $0 ~ ststruct2) &&
      $0 !~ stforward && $0 !~ stother) {
#print "struct: " $0;
    ins = 1;
    tstr = $0;
    gsub (/[^{]/, "", tstr);
    bcount = bcount + length (tstr);
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (bcount <= 0 && length(tstr) > 0) {
      ins = 0;
    }
    if ($0 ~ stend) {
      doend = 1;
    }
    acount = 0;
    sarr[acount] = $0;
    acount = acount + 1;
  } else if (ins == 1 && havestart == 0 && $0 ~ stend) {
#print "end: " $0;
    sarr[acount] = $0;
    acount = acount + 1;
    doend = 1;
  } else if (ins == 1 && $0 ~ /{/) {
#print "{: " $0;
    sarr[acount] = $0;
    acount = acount + 1;
    tstr = $0;
    gsub (/[^{]/, "", tstr);
    bcount = bcount + length (tstr);
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (bcount <= 0 && length(tstr) > 0) {
      ins = 0;
    }
  } else if (ins == 1 && $0 ~ /}/) {
#print "}: " $0;
    sarr[acount] = $0;
    acount = acount + 1;
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (bcount <= 0) {
      if (havestart == 1) {
        doend = 1;
      }
      ins = 0;
    }
  } else if (ins == 1) {
#print "1: " $0;
    sarr[acount] = $0;
    acount = acount + 1;
  }

  if (doend == 1) {
    for (i = 0; i < acount; ++i) {
      print sarr[i];
    }
    exit;
  }
}
