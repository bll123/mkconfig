#!/usr/bin/awk

BEGIN {
  macrostart = "^#[ 	]*define[ 	]*" ARGV[2] "[ 	(]"
  delete ARGV[2];
  ins = 0;
  doend = 0;
#print "macrostart:" macrostart;
}

{
  if (ins == 0 && $0 ~ macrostart) {
#print "start: " $0;
    ins = 1;
    macro = $0;
#print "macroA:" macro;
    gsub (/\/\/.*$/, "", macro);
    gsub (/\/\*.*\*\//, "", macro);
    gsub (/[ 	]*$/, "", macro);
#print "macroAA:" macro;
    doend = 1;
    if ($0 ~ /\\$/) {
      doend = 0;
      gsub (/[	 ]*\\$/, " ", macro);
#print "macroB:" macro;
#print "not end: ";
    }
  } else if (ins == 1) {
#print "cont: " $0;
    macro = macro $0;
#print "macroC:" macro;
    doend = 1;
    if ($0 ~ /\\$/) {
      doend = 0;
      gsub (/[	 ]*\\$/, " ", macro);
#print "macroD:" macro;
#print "not end: ";
    }
  } else if (ins == 1) {
#print "ins = 1; end ";
    doend = 1;
  }

  if (doend == 1) {
    print macro;
    exit;
  }
}
