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
##--Replace the sourceFolder here!
toBeExplodedFolder="/Users/UCB/Documents/UCB/Scriptz/Tests/SourceFolder"

##--Replace the destinaionFolder here!
destinaionFolder="/Users/UCB/Documents/UCB/Scriptz/Tests/DestinationFolder"

##--Replace the zipfolder
zipFolder="/Users/UCB/Documents/UCB/Scriptz/Tests/Zip"

ipaCheck()
{
  for toBeExploded in "$toBeExplodedFolder"/*
    do
      ipaFileExtentions="${toBeExploded##*.}"                     ##extract just the FileExtention without the dot
      echo File to be Exploded: $toBeExploded
      echo FileExtention: $ipaFileExtentions
      if [ $ipaFileExtentions == "ipa" ]                            ##if the FileExtention equals ipa
        then
          amountOfIpas+=("$toBeExploded")                      ##put the file in an array
          echo array: $amountOfIpas
          ipaArrayLength=${#amountOfIpas[@]}                        ##Get the array length for the next statement
          echo arraylenght: $ipaArrayLength
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
    unZip
    extractEntitlements
    cleanup
  done
}

unZip()
{
  printf "${GREEN}Unzipping the ipa${NC}\n"
  cd $toBeExplodedFolder
  unzip "$ogIpa" -d "$zipFolder/$ogIpa"                                                ##unzip the ipa in a temp folder
}

extractEntitlements()
{
  printf "${GREEN}Extracting the entitlements${NC}\n"
  cd "$zipFolder/$ogIpa/Payload"
  payloadApp=$(ls | grep '.app')
  cd "$zipFolder/$ogIpa"
  entitlementsFileName="$ogIpa""_entitlements.txt"
  codesign -d -vv --entitlements $entitlementsFileName ./Payload/"$payloadApp"
}

cleanup()
{
  cd "$zipFolder/$ogIpa"
  mv $entitlementsFileName $destinaionFolder
  cd $zipFolder
  rm -rf $ogIpa
}

  ipaCheck
  getOgIpa
