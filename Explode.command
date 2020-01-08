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
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"  ##Homedir
toBeExplodedFolder="$DIR/toBeExploded"

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
    exit 113                                                        ##exit with code 113
  fi
}

getOgIpa()
{
  printf "${GREEN}Get the og app name${NC}\n"
  for apps in "$toBeExplodedFolder"/*                                             ##for every file in the folder
    do
    ogIpa=$(echo "$(basename "$apps")")                                         ##Get the filename with extention
    printf "${YELLOW}The ipa that will be processed: ${GREEN}$ogIpa${NC}\n"
  done
}

unZip()
{
  printf "${GREEN}Unzipping the ipa${NC}\n"
  cd $toBeExplodedFolder
  unzip "$ogIpa" -d $DIR/$ogIpa                                                ##unzip the ipa in a temp folder
}

extractEntitlements()
{
  printf "${GREEN}Extracting the entitlements${NC}\n"
  cd $DIR/$ogIpa/Payload
  payloadApp=$(ls | grep '.app')
  cd "$DIR/$ogIpa"
  codesign -d -vv --entitlements entitlements.txt ./Payload/"$payloadApp"         ##codesign the entitlements
}

copyInfo()
{
  cd $DIR/$ogIpa/Payload/"$payloadApp"
  info=$(ls | grep 'Info.plist')
  if [[ $info = 'Info.plist' ]]
    then
      cp -v $DIR/$ogIpa/Payload/"$payloadApp"/$info $DIR/$ogIpa
      copyConfig
    else
      copyConfig
  fi
  printf "${GREEN}Copy the Config.plist${NC}\n"
}

copyConfig()
{
  cd $DIR/$ogIpa/Payload/"$payloadApp"
  config=$(ls | grep 'Config.plist')
  echo $config
  if [[ $config = 'Config.plist' ]]
    then
      cp -v $DIR/$ogIpa/Payload/"$payloadApp"/Config.plist $DIR/$ogIpa
      getCertificateDate
    else
      getCertificateDate
  fi
}

getCertificateDate()
{
  printf "${GREEN}Getting the certificate dates${NC}\n"
  codesign -d --extract-certificates $DIR/$ogIpa/Payload/"$payloadApp"
  certs=$(openssl x509 -inform DER -in codesign0 -noout -nameopt -oneline -dates)
  printf "${BLUE}certs: $certs ${NC}\n"
  echo $certs > $DIR/$ogIpa/SigningCertificate.txt
  copyIpa
}

copyIpa()
{
  printf "${GREEN}Copy the Config.plist${NC}\n"
  mv -v $toBeExplodedFolder/$ogIpa $DIR/$ogIpa

}

  ipaCheck
  getOgIpa
  unZip
  extractEntitlements
  copyInfo
