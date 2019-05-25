cls
#Pre Req's
#Install-module AzureADPreview

$Credential = Get-Credential
connect-azuread -Credential $Credential

#Lets Automate it more by specifying username from the environment variables!
$LUN = $env:USERNAME

#Make it lowercase or match will fail
$SLUN = $LUN.ToLower()
#$AADUN = $LUN.Substring(1)

#NO LONGER NEEDED, MATCHING WITH UPN Since their computer logins are Fi+Lastname going to make a new variable which trims string of $evn:Username to remove first letter

$AFULL = Get-AzureADUser -All $True | where{$_.UserPrincipalName.contains($SLUN)} 
$ADUN = Get-AzureADUser -All $True | Where{$_.UserPrincipalName.contains($SLUN)} | Select ObjectId

#Return ONLY the objectID
$UTFGL = $ADUN.ObjectId


#Make user readable to ODSYNC
$EUID = $UTFGL -replace('\-','%2D')

$GUPN = Get-AzureADUser -All $True | Where{$_.UserPrincipalName.Contains($SLUN)} | Select UserPrincipalName
$GUPNDATA = $GUPN.UserPrincipalName

$GD1 = $GUPNDATA -replace('\@','%40')
$GD2 = $GD1 -replace('\.','%2E')

#This one might be optional 
#$ODSTART = 'odopen://launch'

#Might be the only one required
#$ODSIGNIN = 'odopen://sync?useremail='+$GD2

$ODSIGNIN = 'odopen://sync?useremail='+$GD2

Sleep -Seconds 15

 
#import all of our SPO data
$CSVData = import-csv $ENV:USERPROFILE\Desktop\ODAUTOMATE.csv -Header webTitle,azureGroupID,SiteID,webid,webLogoUrl,weburl,listid

#Get a list of all the Teams/SPO sites that user is a member of: 
 $ALLTEAMS = Get-AzureADMSGroup | where{$_.proxyAddresses -like "*SPO*" } 
 #^^Get all the azure adms(azure ad connected to exchange online groups) where SPO is in the proxy -- idenfities SPO linked and non SPO groups
 #init array to capture team membership
 $MemberOF = @()
 foreach($Team in $ALLTEAMS){

    if(Get-AzureADGroupMember -ObjectId $Team.Id | where{$_.UserprincipalName -eq $GUPNDATA}) {
        write-host $AFULL.DisplayName is a member of $Team.DisplayName -ForegroundColor Green
        $MemberOF += $Team.Id
    }
    else{
    }

 }

 
 #only retrieve the data for the teams the user is a member of
 foreach($MEM in $MemberOF){
        foreach($LINE in $CSVData){
                if($MEM -eq $LINE.azureGroupID){
                    #declare our variable as i can't concat strings from var's to save my life...
                $STID = $LINE.siteID
                $WBID = $LINE.webid
                $WBTITRAW = $LINE.webTitle
                $WBTIT = ((($WBTITRAW.Replace(' ','%20')).Replace('(','%28')).Replace(')','%29')).Replace('-','%2D')
                $WBLOGORAW = $LINE.webLogoUrl
                $WBLOGO = (($WBLOGORAW.Replace("'","%27")).Replace('&','%26')).Replace('=','%3D')
                $WBURLRAW = $LINE.weburl
                $WBURL = ($WBURLRAW.Replace(':','%3A')).Replace('.','%2E')
                $LISTIDRAW = $LINE.listid
                $LISTID ='%7B'+$LISTIDRAW+'%7D'
                $TEST1  = 'odopen://sync/?userId='
                $PREFORMATTEDSTUFF = $EUID+'&userEmail='+$GD2+'&isSiteAdmin=0&siteId='+'%7B'+$STID+'%7D'+'&webId='+'%7B'+$WBID+'&webTitle='+$WBTIT+'&webTemplate=64&webLogoUrl='+$WBLOGO+'&webUrl='+$WBURL+'&onPrem=0&listId='+$LISTID+'&listTemplateTypeId=101&listTitle=Documents&scope=OPENLIST'
                $FORMATTEDSTUFF = (((((($PREFORMATTEDSTUFF.Replace(' ','%20')).Replace('(','%28')).Replace(')','%29')).Replace('-','%2D')).Replace('/','%2F')).Replace('_','%5F')).Replace('?','%3F')
                $FinalString = $TEST1+$FORMATTEDSTUFF

                    write-host UserGroup matches $LINE.webTitle -ForegroundColor Green
                    write-host $FinalString
                    Start-Process $FinalString
                    sleep -seconds 10
                    
                }
                else{
                    #write-host did not find
                 }

        
        }
    

 }

#Cleanup
Remove-Item -Path  $ENV:USERPROFILE\Desktop\ODAUTOMATE.csv

Write-Host   " Teams to Onedrive mapping COMPLETED" -ForegroundColor Cyan -BackgroundColor Black