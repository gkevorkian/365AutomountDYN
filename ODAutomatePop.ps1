#$TempCred = Get-Credential

#Connect to the admin tenant site
Connect-pnponline -Url "https://mydomain-admin.sharepoint.com" -Credentials $TempCred

#Get list of all sites
$PNPSITES = get-pnptenantsite -detailed | where{$_.Template -eq "GROUP#0" }
Clear-Content -Path "C:\users\greg\Desktop\ODAUTOMATE.csv"
foreach($PNP in $PNPSITES){
    
    write-host Connecting to $PNP.Title -ForegroundColor Yellow
    Connect-PnPOnline -url $PNP.URL -Credentials $TempCred
    write-host Gathering Associated membership info -foregroundColor Green
    #Initialize custom object to store retrieved data
    $SPOData = New-Object pscustomobject -Property @{
            webTitle=$PNP.Title
            azureGroupID=((Get-PnPGroup -AssociatedMemberGroup | Get-PnpGroupMembers | where{$_.Id -eq "7" } | Select LoginName).LoginName).Split("|")[2]
            siteID=(get-pnpsite -Includes id | select id).id
            webid=(get-pnpweb | select Id).Id
            webLogoUrl=(get-pnpweb -includes SiteLogoUrl | select SiteLogoUrl).SiteLogoUrl
            webUrl=($PNP.Url)
            listId=(get-pnplist -Identity "Documents" | Select id).id


        }
    $SPOData | Select webTitle,azureGroupID,siteID,webid,webLogoUrl,webUrl,listId | Export-Csv -Path C:\users\greg\desktop\ODAUTOMATE.csv -NoTypeInformation -Append
}