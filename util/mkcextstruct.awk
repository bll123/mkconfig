#!/usr/bin/awk

BEGIN {
  ststruct1 = "(struct|union|enum)[	 ]*{"
  ststruct2 = "(struct|union|enum)[	 ]*$"
  ststart = "(struct|union|enum)[	 ]*" ARGV[2];
  stforward = "(struct|union|enum)[	 ]*" ARGV[2] "[	 ]*;";
  stother = "(struct|union|enum)[	 ]*" ARGV[2] "[	 ]*[*a-zA-Z_]";
  stend = "[	 ]" ARGV[2] "_t";
  delete ARGV[2];
  bcount = 0;
  acount = 0;
  ins = 0;
  havestart = 0;
  doend = 0;
  hadend = 0;
  sarr[0] = "";
  nsarr[0] = "";
  savens = "";
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
    hadend = 0;
    delete nsarr;
    nsarr[0] = "";
    savens = "";
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
    hadend = 0;
    delete nsarr;
    nsarr[0] = "";
    savens = "";
    ins = 1;
    tstr = $0;
    gsub (/[^{]/, "", tstr);
    bcount = bcount + length (tstr);
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (bcount <= 0 && length(tstr) > 0) {
      ins = 0;
      bcount = 0;
      savens = "";
      delete nsarr;
      nsarr[0] = "";
    }
    if ($0 ~ stend) {
      doend = 1;
    }
    acount = 0;
    sarr[acount] = $0;
    acount = acount + 1;
  } else if (ins == 1 && havestart == 0 && $0 ~ stend) {
#print "end: " $0;
    hadend = 0;
    sarr[acount] = $0;
    acount = acount + 1;
    doend = 1;
  } else if (ins == 1 && $0 !~ /(struct|union)[	 ]*{/ &&
        $0 ~ /(struct|union)[	 ]/ && $0 !~ /(struct|union)[	 ].*;/) {
#print "struct: " $0;
    hadend = 0;
    savens = "";
    sarr[acount] = $0;
    acount = acount + 1;
    tstr = $0;
    sub (/(struct|union) */, "&C_ST_", tstr);
    sarr [acount - 1] = tstr;
    tstr = $0;
    gsub (/[^{]/, "", tstr);
    bcount = bcount + length (tstr);
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (bcount <= 0 && length(tstr) > 0) {
      ins = 0;
    }
    if (ins == 1) {
      tstr = $0;
      sub (/[	 ]*(struct|union)[	 ]*/, "", tstr);
      sub (/[	 ].*/, "", tstr);
#print "nested: ", tstr;
      savens = tstr;
      if (bcount > 1) {
        nsarr[bcount] = tstr;
        savens = "";
#print "nested save: " tstr;
      }
    }
  } else if (ins == 1 && $0 ~ /{/) {
#print "{: " $0;
    hadend = 0;
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
    if (ins == 1 && bcount > 1 && savens != "") {
#print "nested last: ", savens;
      if (bcount > 1) {
        nsarr[bcount] = savens;
#print "nested save: " savens;
      }
      savens = "";
    }
  } else if (ins == 1 && $0 ~ /}/) {
#print "}: " $0;
    sarr[acount] = $0;
    acount = acount + 1;
    tstr = $0;
    gsub (/[^}]/, "", tstr);
    bcount = bcount - length (tstr);
    if (length(tstr) > 0 && $0 !~ /}[	 ]*;/) {
#print "}: hadend: =1" $0;
      hadend = 1;
    }
    if (bcount <= 0) {
#print "}: bcount: 0";
      if (havestart == 1) {
        doend = 1;
      } else {
        hadend = 0;
        savens = "";
        bcount = 0;
        acount = 0;
        delete nsarr;
        nsarr[0] = "";
      }
      ins = 0;
    } else if (length (tstr) > 0 && $0 !~ /}[	 ;]*$/) {
#print "end struct dcl: " $0;
      tstr = $0;
      sub (/}.*/, "};", tstr);
      sarr [acount - 1] = tstr;
      if (nsarr[bcount + 1] != "") {
        tstr = $0;
        sub (/}[	 ]*/, "C_ST_" nsarr[bcount + 1] " ", tstr);
        sarr [acount] = tstr;
        acount = acount + 1;
      }
      hadend = 0;
    }
  } else if (ins == 1) {
#print "1: " $0;
#print "1: hadend:" hadend;
    if (hadend == 1 && nsarr[bcount + 1] != "") {
      if ($0 ~ /[	 *]*[_A-Za-z]/) {
#print "1: hadend: match"
        sarr[acount] = " C_ST_" nsarr[bcount + 1] " " $0;
        acount = acount + 1;
      } else {
        sarr[acount] = $0;
        acount = acount + 1;
      }
    } else {
      sarr[acount] = $0;
      acount = acount + 1;
    }
    hadend = 0;
  }

  if (doend == 1) {
    for (i = 0; i < acount; ++i) {
      print sarr[i];
    }
    exit;
  }
}
