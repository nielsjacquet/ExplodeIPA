#!/usr/bin/env bash

##cosmetic functions and Variables
##Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'
BLUE='\033[0;34m'

##Break function for readabillity
BR()
{
  echo "  "
}

##DoubleBreak function for readabillity
DBR()
{
  echo " "
  echo " "
}

##Paths
#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"  ##Homedir
DIR="/Users/UCB/Documents/UCB/Scriptz/ExplodeIpa"
toBeExplodedFolder="$DIR/toBeExploded"

helpFunction()
{
  echo ""
  echo "Usage: $0 -i ipaPath"
  echo -e "\t-i ipaPath -- REQUIRED "
  exitProcedure # Exit script after printing help
}

copyToExplodedFolder()
{
  echo Copy the ipa to the to be exploded folder
  cp "$ipaArg" "$toBeExplodedFolder"
}

ipaCheck()
{
  for toBeExploded in "$toBeExplodedFolder"/*
    do
      ipaFileExtentions="${toBeExploded##*.}"                     ##extract just the FileExtention without the dot
      echo File to be Exploded: $toBeExploded
      echo FileExtention: $ipaFileExtentions
      if [ $ipaFileExtentions == "ipa" ]                            ##if the FileExtention equals ipa
        then
          amountOfIpas+=("$toBeExploded")                         ##put the file in an array
          ipaArrayLength=${#amountOfIpas[@]}                        ##Get the array length for the next statement
      fi
    done
  if [[ $ipaArrayLength < "1" ]]                                    ## if the array length is less than 1, exit the script
   then
    printf "${RED}no ipa present in the toBeExplodedFolder: $toBeExplodedFolder${NC}\n"
    exitProcedure                                                        ##exit with code 113
  fi
}

getOgIpa()
{
  printf "${GREEN}Get the og app name${NC}\n"
  for apps in "$toBeExplodedFolder"/*                                             ##for every file in the folder
    do
    ogIpa=$(echo "$(basename "$apps")")                                         ##Get the filename with extention
    filename="${ogIpa%.*}"
    printf "${YELLOW}The ipa that will be processed: ${GREEN}$ogIpa${NC}\n"
    printf "${YELLOW}The foldername from the ipa: $filename${NC}\n"
  done
}

unZip()
{
  printf "${GREEN}Unzipping the ipa${NC}\n"
  cd $toBeExplodedFolder
  unzip "$ogIpa" -d "$DIR/$filename"
}

extractEntitlements()
{
  printf "${GREEN}Extracting the entitlements${NC}\n"
  cd "$DIR/$filename/Payload"
  payloadApp=$(ls | grep '.app')
  cd "$DIR/$filename"
  codesign -d -vv --entitlements entitlements.txt ./Payload/"$payloadApp"         ##codesign the entitlements
}

copyInfo()
{
  cd $DIR/"$ogIpa"/Payload/"$payloadApp"
  info=$(ls | grep 'Info.plist')
  if [[ $info = 'Info.plist' ]]
    then
      cp -v $DIR/"$filename"/Payload/"$payloadApp"/$info "$DIR/$filename"
      copyConfig
    else
      copyConfig
  fi
  printf "${GREEN}Copy the Config.plist${NC}\n"
}

copyConfig()
{
  cd $DIR/"$filename"/Payload/"$payloadApp"
  config=$(ls | grep 'Config.plist')
  echo $config
  if [[ $config = 'Config.plist' ]]
    then
      cp -v $DIR/"$filename"/Payload/"$payloadApp"/Config.plist "$DIR/$filename"
      getSigningCertificateDate
    else
      getSigningCertificateDate
  fi
}

getSigningCertificateDate()
{
  printf "${GREEN}Getting the Signing certificate dates${NC}\n"
  codesign -d --extract-certificates $DIR/"$filename"/Payload/"$payloadApp"
  certs=$(openssl x509 -inform DER -in codesign0 -noout -nameopt -oneline -dates)
  printf "${BLUE}certs: $certs ${NC}\n"
  echo "SigningCertificate Dates:" > $DIR/"$ogIpa"/SigningCertificate.txt
  echo $certs >> $DIR/"$filename"/SigningCertificate.txt
  echo "" >> $DIR/"$filename"/SigningCertificate.txt
  getProvisioningProfileDate
}

getProvisioningProfileDate()
{
  printf "${GREEN}Getting the Provisioning Profile end date${NC}\n"
  prov=$(strings $DIR/$filename/Payload/"$payloadApp"/embedded.mobileprovision | grep -A1 ExpirationDate )
  printf "${BLUE}Provisioning Profile end date: $prov ${NC}\n"
  echo "Provisioning Profile end date:" >> $DIR/"$filename"/SigningCertificate.txt
  echo $prov >> $DIR/"$filename"/SigningCertificate.txt
  copyIpa
}

copyIpa()
{
  printf "${GREEN}Copy the Config.plist${NC}\n"
  mv -v $toBeExplodedFolder/"$ogIpa" $DIR/"$filename"
}

exitProcedure()
{
  exit 1
}

while getopts "i:?:h:" opt
do
   case "$opt" in
      i ) ipaArg="$OPTARG" ;;               # Ipa path argument
      ? ) helpFunction ;;                   # Print helpFunction in case parameter is non-existent
      h ) helpFunction ;;                   # Print helpFunction in case parameter is non-existent
   esac
done

if [[ -z $ipaArg ]]
  then
    echo ipaArg is empty: $ipaArg
    ipaCheck
    getOgIpa
    unZip
    extractEntitlements
    copyInfo
    open $DIR/"$filename"
fi

if [[ ! -z $ipaArg  ]]
  then
   echo ipaArg is not empty: $ipaArg
   copyToExplodedFolder
   ipaCheck
   getOgIpa
   unZip
   extractEntitlements
   copyInfo
   open $DIR/"$filename"
fi
