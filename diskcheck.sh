#!/bin/bash
red='\033[1;31m'
yellow='\033[1;33m'
blue='\033[1;34m'
white='\033[1;37m'
nc='\033[0m'
output="${blue}Mount Point\tPercent Used${nc}\n"
for i in $(df -h | tail -n +2 | sed -e 's/\s\s*/:/g' | cut -d: -f1,5 | sed -e 's/%$//g'); 
do
	hname=$(echo $i | cut -d: -f1)
	usedsize=$(echo $i | cut -d: -f2)
	if [ $usedsize -ge 45 ] ; then
		output=$output"${white}$hname${nc}\t${red}$usedsize%${nc}\n"
	elif [ $usedsize -ge 20 ] ; then
		output=$output"${white}$hname${nc}\t${yellow}$usedsize%${nc}\n"
	else
		continue
		#echo "OK! $hname is at $usedsize%"
	fi
done
echo -e $output
