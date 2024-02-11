#!/bin/bash
SourceProject=$1
DestinationProject=$2
SourceDefineName=`echo $SourceProject | tr a-z A-Z`
DestinationDefineName=`echo $DestinationProject | tr a-z A-Z`

mkdir "$DestinationProject" && cd "$DestinationProject"
cp -r ../"$SourceProject"/Include .
cp -r ../"$SourceProject"/Source .
cp ../"$SourceProject"/Makefile .

mv Include/"$SourceProject".h Include/"$DestinationProject".h
mv Source/"$SourceProject".cpp Source/"$DestinationProject".cpp

sed -i "s/__${SourceDefineName}_H__/__${DestinationDefineName}_H__/" Include/$DestinationProject.h

ls Source/*.cpp | xargs -I{} sed -i "s/#include \"..\/Include\/${SourceProject}.h\"/#include \"..\/Include\/${DestinationProject}.h\"/" {}
