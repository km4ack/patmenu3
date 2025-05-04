#!/bin/bash
#
# a simple bash script for creating input file for voacapl for the current
# month and running the prediction
# - fetches SSN data from internet source
# - validates user input data
# - outputs a REL (S DBW) table as a function of bands vs. time
# 
# Author: Jari PerkiÃ¶mÃ¤ki OH6BG
# 12 June 2016: initial release
# 18 June 2016: added Long-Path predictions
# 18 June 2016: added choice of Year, Month, TX Power & TX Mode
# 19 June 2016: running both Short-Path and Long-Path circuits by default
#
# modified to work as stand alone script or with Pat Menu
# 28MARCH2025 last edit KM4ACK

# ssn reference
# https://services.swpc.noaa.gov/json/solar-cycle/predicted-solar-cycle.json
# grep 2025-03 -A 6 ssn.json | grep low_ssn | awk '{print $2}' | sed 's/\..*//'



# VOACAP input & output files
INP=~/itshfbc/run/voacapx.dat
OUT=~/itshfbc/run/voacapx.out
# sunspot file location
SSN=~/itshfbc/ssn.txt
LOGO=${MYPATH}/pmlogo.png
MAIN=${MYPATH}/patmenu

# clear screen
clear

if [ -z $2 ]; then
  echo;echo;echo "usage: voa.sh <tx-grid_square> <rx-grid_square> <current_sun-spot-number>"
  echo;echo "note: grid squares should be 6 characters"
  echo "note: sunspot number can be omitted. if omitted, forecast ssn will be used"
  exit
fi



# get current month and year
dm=$(date +"%m:%Y")
IFS=": " read -r MO YR <<< "$dm"
s1=$(( $MO + 0 )) # strip leading zero

# function: trim whitespace from user input
trim() {
    local var="$*"
    var="${var#"${var%%[![:space:]]*}"}"   # remove leading
    var="${var%"${var##*[![:space:]]}"}"   # remove trailing
    echo -n "$var"
}

s1=$(date +%m | sed 's/^0//')



tx_grid=$1
rx_grid=$2

tx_lat=$(/usr/local/bin/locator ${tx_grid} | grep Coor | awk '{print $8}')
tx_long=$(/usr/local/bin/locator ${tx_grid} | grep Coor | awk '{print $4}')
rx_lat=$(/usr/local/bin/locator ${rx_grid} | grep Coor | awk '{print $8}')
rx_long=$(/usr/local/bin/locator ${rx_grid} | grep Coor | awk '{print $4}')

TX=$(printf "%-20s" "TX")

# read TX latitude and check user input
while [[ ! $TL1 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; do
    #echo -ne "TX latitude  (-90...90)   "
    TL=${tx_lat}
    TL=$(trim $TL)
    TL1=$( awk -v n1=$TL -v n2=90 -v n3=-90 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )
done

# add North or South (N/S)
TLA=$( awk -v n1=$TL1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%6sS", n1); } else printf ("%6sN", n1);}' )

# read TX longitude and check user input
while [[ ! $TK1 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; do
    #echo -ne "TX longitude (-180...180) "
    TK=${tx_long}
    TK=$(trim $TK)
    TK1=$( awk -v n1=$TK -v n2=180 -v n3=-180 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )
done
		    
# add East or West (E/W)
TLO=$( awk -v n1=$TK1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%7sW", n1); } else printf ("%7sE", n1);}' )

cat << END

RECEIVER (RX)
---------------------------
END

RX=$(printf "%-20s" "RX")

# read RX latitude and check user input
while [[ ! $RL1 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; do
    #echo -ne "RX latitude  (-90...90)   "
    RL=${rx_lat}
    RL=$(trim $RL)
    RL1=$( awk -v n1=$RL -v n2=90 -v n3=-90 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )
done

# add North or South
RLA=$( awk -v n1=$RL1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%6sS", n1); } else printf ("%6sN", n1);}' )

# read TX longitude and check user input
while [[ ! $RK1 =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; do
    #echo -ne "RX longitude (-180...180) "
    RK=${rx_long}
    RK=$(trim $RK)
    RK1=$( awk -v n1=$RK -v n2=180 -v n3=-180 'BEGIN {if (n1<n3 || n1>n2) printf ("%s", "a"); else printf ("%.2f", n1);}' )
done

# add East or West
RLO=$( awk -v n1=$RK1 -v n2=0 'BEGIN {if (n1<n2) { n1=substr(n1,2); printf ("%7sW", n1); } else printf ("%7sE", n1);}' )

# Choose Power
PWR="1500 500 100 5"
PW="0.0800"
PW="0.0040"

# Choose Mode
MODE="CW SSB AM"
MD="24.0"


# ssn.txt: extract current year's SSN line, and the SSN for the month
#s2=$(( $s1 + 2 )) # set correct field to get monthly SSN from the grepped line in ssn.txt
#ssn=$(grep $YR $SSN | tr -s ' ' | cut -d ' ' -f $s2)
if [ -z $3 ]; then
  ssn=$(grep `date +%Y-%m` -A 6 ssn.json | grep low_ssn | awk '{print $2}' | sed 's/\..*//')
  ssn="${ssn}."
else
  ssn=${3}.
fi

s3=$( awk -v n1=$s1 'BEGIN { printf ("%5.2f", n1); }' ) # set fix field (5 char, .00) for month input

# read more about fine-tuning your input file:
# http://www.voacap.com/voacapw.html
# http://www.voacap.com/frequency.html

cat << END | tee $INP 
LINEMAX     999       number of lines-per-page
COEFFS    CCIR
TIME          1   24    1    1
MONTH      $YR $s3
SUNSPOT   $ssn
LABEL     $TX$RX
CIRCUIT  $TLA  $TLO   $RLA  $RLO  S     0
SYSTEM       1. 155. 3.00  90. $MD 3.00 0.10
FPROB      1.00 1.00 1.00 0.00
ANTENNA       1    1    2   30     0.000[samples/sample.00    ]  0.0    $PW
ANTENNA       2    2    2   30     0.000[samples/sample.00    ]  0.0    0.0000
FREQUENCY  3.60 5.30 7.1010.1014.1018.1021.1024.9028.20 0.00 0.00
METHOD       30    0
BOTLINES      8   12   21
TOPLINES      1    2    3    4    6
EXECUTE
QUIT

END

# calculate prediction
echo -e "\nCalculating Short-Path..."
voacapl -s ~/itshfbc

(tail -n +27 $OUT | head -n 5 &&  grep -e'-  REL' $OUT && grep -e'-  S DBW' $OUT) | ${MYPATH}/bin/voacap/rel.pl > ${MYPATH}/bin/voacap/voacap.txt


cat << END > $INP 
LINEMAX     999       number of lines-per-page
COEFFS    CCIR
TIME          1   24    1    1
MONTH      $YR $s3
SUNSPOT     $ssn
LABEL     $TX$RX
CIRCUIT  $TLA  $TLO   $RLA  $RLO  L     1
SYSTEM       1. 155. 3.00  90. $MD 3.00 0.10
FPROB      1.00 1.00 1.00 0.00
ANTENNA       1    1    2   30     0.000[samples/sample.00    ]  0.0    $PW
ANTENNA       2    2    2   30     0.000[samples/sample.00    ]  0.0    0.0000
FREQUENCY  3.60 5.30 7.1010.1014.1018.1021.1024.9028.20 0.00 0.00
METHOD       30    0
BOTLINES      8   12   21
TOPLINES      1    2    3    4    6
EXECUTE
QUIT

END

utc_time=$(date -u +%H:%M)
clear && #cat ./voacap.txt
yad --width=700 --height=450 --text-align=center --center --title="voacap prediction" \
    --image ${LOGO} --window-icon=${LOGO} --image-on-top --separator="|" --item-separator="|" \
    --text-info --text="<b>TX Grid - $1\rRX Grid - $2</b>\rCurrent Time ${utc_time}z"\
    --button="CLOSE":2 <${MYPATH}/bin/voacap/voacap.txt

${MAIN} & exit

