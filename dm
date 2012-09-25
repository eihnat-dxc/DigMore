#!/usr/bin/perl
### DigMore v1.2.1 - Pavol Leskovsky ###
use Term::ANSIColor;

chomp ($home=`echo \$HOME`);
$home .="/";
chomp ($timezone=`date +%Z`);
$answfile="answ.dm";        # ___---- constants section ----___
$noexfile="noex.dm";
$maxfile=20000;
$aaf=";; flags:";
$answerf=";; ANSWER SECTION:";
$clraa='bold white';
$clran='white';
$clrqr="bold yellow";
$clrbgdbl=" on_red";
$clrodd="white";
$clrodderr="bold red";
$oddelovac="-------------------------------------------------------"."\n";
$qrprefix=">>  ";
$noexist="Can't find this entry in DNS.\n";
$clrnoex="bold red";
$clrreport="bold green";


sub filebck {
    my ($filename) = $_[0];
    if ((-s "${home}${filename}") >= $maxfile) {
        if (-e "${home}old-${filename}") {
            unlink("${home}old-${filename}");
        }
        rename("${home}${filename}", "${home}old-${filename}");
        }

}


sub rmvdt {                             #___---- remove dot ----___
    my (@slovo) = split(//,$_[0]);
    if ($slovo[-1] eq ".") {
        pop(@slovo);
    }
    return join(//,@slovo);
}


sub jecislo {                           # ___---- number identify function ----___
    my ($q) = $_[0];
    @qznak = split(//,$q);
    if (($qznak[-1] ge "0") && ($qznak[-1] le "9")){
        return 1;
    }
    return 0;
}


sub dg {                                # ___---- resolving function ----___
    my ($q) = $_[0];
    $otazka=$q;
    ++$countmain;
    if (jecislo($q)) {
       $q = "-x ".$q;
    }
    @in=`dig $q +time=3 +tries=2`;               # ######## DIG ######## #
    $aaflag=0;
    $dflag=0;
    $i=0;
    $j=0;
    @answer="";
    $duplicate=0;
    undef @answerfrm;
    do {
            if (($in[$i] =~ /$aaf/) && ($in[$i] =~ /aa/)) { # najdi riadok a zisti aa
                $aaflag = 1;
            }
            if ($in[$i] =~ /$answerf/) { # najdi riadok a zisti answers
                do {
                    $answer[$j]=$in[$i+$j+1]; # answer raw
                    @answerline=split(/\s+/,$answer[$j]);
                    if (defined $answerline[1]) {
                        $answerfrm[$j]=(&rmvdt($answerline[0]))."\t".$answerline[-2]."\t".(&rmvdt($answerline[-1]))."\n"; # answer formated
                        }
                    ++$j;
                    if (($answerline[-2] eq "A") || ($answerline[-2] eq "PTR")) {
                        ++$duplicate;
                    }
                } until $in[$i+$j+1] =~ /^\s*$/;
            }
            ++$i;
    } until $i>=@in;
    if ($duplicate > 1) {
        $dflag=1;
    }
    if (@answerfrm) {
        print ODPOVEDE @answerfrm;
    } else {
        print ODPOVEDE $otazka."\t".$noexist;
        print UNRESOLVED $otazka."\n";
    }
    return ($dflag, $aaflag, @answerfrm);
}

# --------------------------------------------- MAIN PROGRAM

open FILE, "<$ARGV[0]";
chomp (@inlist=<FILE>);
&filebck($answfile);
&filebck($noexfile);
open ODPOVEDE, ">>${home}${answfile}";
open UNRESOLVED, ">>${home}${noexfile}";
$errnoex=0;
$nomatch=0;
$counteq=0;
$countdbl=0;
$countmain=0;
$countrow=0;

                                ######################## Time
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
my @abbr = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
$month = $abbr[$mon];
$yr= $year+1900;
print color ($clrreport), "\nDNS resolution started at $hour:$min:$sec $mday\/$month\/$yr $timezone\n", color("reset");
print color ($clrodd), $oddelovac, color ("reset");
print ODPOVEDE "\n************** $hour:$min:$sec $mday\/$month\/$yr **************\n";
print UNRESOLVED "\n************ $hour:$min:$sec $mday\/$month\/$yr ************\n";

do {
$multi=0;
@queries=split(/\s+/,shift(@inlist));
    if (defined ($queries[1])) {                # 2 stlpce ??
        my ($d1, $f1, @answ1)=dg($queries[0]);
        my ($d2, $f2, @answ2)=dg($queries[1]);
        ++$countrow;
        if ($d1) {                            # double color
            $bg1=$clrbgdbl;
            ++$countdbl;
        } else {
            $bg1="";
        }
        if ($d2) {
            $bg2=$clrbgdbl;
            ++$countdbl;
        } else {
            $bg2="";
        }

        if ($f1) {
            $textcolor1=$clraa;
        } else {
            $textcolor1=$clran;
        }
        if ($f2) {
            $textcolor2=$clraa;
        } else {
            $textcolor2=$clran;
        }
        print color ($clrqr.$bg1),(sprintf("%03d", $countrow)).$qrprefix.$queries[0], color("on_black"), "\n", color ("reset");  # answer1
        if (defined ($answ1[0])) {
            print color ($textcolor1), @answ1, color ("reset");             # existuje
        } else {
            print color ($clrnoex), $noexist, color ("reset");              # neexistuje
            $errnoex++;
        }

        print color ($clrqr.$bg2),(sprintf("%03d", $countrow)).$qrprefix.$queries[1], color("on_black"), "\n", color ("reset");  # answer2
        if (defined ($answ2[0])) {
            print color ($textcolor2), @answ2, color ("reset");             # existuje
        } else {
            print color ($clrnoex), $noexist, color ("reset");              # neexistuje
            $errnoex++;
        }
                                                    ####### A = PTR ? #######
       if ((defined ($answ1[0])) && (defined ($answ2[0]))) {
        $counteq=0;
        undef @tst;
        if (jecislo($queries[0])) {
            while (@answ2) {
                @tst=split(/\s+/,shift(@answ2));
                if ($tst[-1] eq $queries[0]) {
                   ++$counteq;
                }
            }
        } elsif (jecislo($queries[1])) {
            while (@answ1) {
                @tst=split(/\s+/,shift(@answ1));
                if ($tst[-1] eq $queries[1]) {
                    ++$counteq;
                }
            }
        }
        if (not $counteq) {
            ++$nomatch;
            print color ($clrodderr), $oddelovac, color ("reset");
        } else {

            print color ($clrodd), $oddelovac, color ("reset");
        }
        } else {
            print color ($clrodd), $oddelovac, color ("reset");
        }

    }


        elsif (defined ($queries[0])) {             # 1 stlpec
            my ($d0, $f0, @answ0)=dg($queries[0]);
            ++$countrow;
            if ($f0) {
                $textcolor0=$clraa;
            } else {
                $textcolor0=$clran;
            }
            if ($d0) {
                $bg0=$clrbgdbl;
                ++$countdbl;
            } else {
                $bg0="";
            }

            print color ($clrqr.$bg0),(sprintf("%03d", $countrow)).$qrprefix.$queries[0], color("on_black"), "\n", color ("reset"); # answer0
            if (defined ($answ0[0])) {
                print color ($textcolor0), @answ0, color ("reset");         # existuje
            } else {
                print color ($clrnoex), $noexist, color ("reset");          # neexistuje
                $errnoex++;
            }
            print color ($clrodd), $oddelovac, color ("reset");                    # oddelovac
        }

} while(@inlist);

print color ($clrreport), "Entry not exists: ".$errnoex."\/$countmain\n", color ("reset");
if ($countrow < $countmain) {
    print color ($clrreport), "A - PTR not match: ".$nomatch."\n", color ("reset");
}
if ($countdbl) {
    print color ($clrqr.$clrbgdbl), "Duplicate warnings: ".$countdbl, color ("on_black"),"\n", color("reset");
    }
print color ("reset");
print "\n";
close FILE;
close ODPOVEDE;
close UNRESOLVED;
