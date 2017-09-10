#directory path 
$dir = "C:\NTFS"
$dc = "dc02"
$ou = "OU=Groups,OU=Mengen,OU=DEMO,DC=demo01,DC=it-koehler,DC=com"
$domainadmin = "demo01\Administrator"

# foldername 
$NewFolder = Read-Host -Prompt "please enter a Name"
$folderpath = "$dir\$NewFolder"

#check modules loaded

$ADModule='ActiveDirectory'
    if (Get-Module -Name $ADModule) {
        write-host 'Module' $ADModule 'already loaded'
    }
    else {
        Import-Module $ADModule -force
        write-host 'Module' $ADModule 'loaded successfully'
    }


$NTFSModule='NTFSSecurity'
    if (Get-Module -Name $NTFSModule) {
        write-host 'Module' $NTFSModule 'already loaded'
    }
    else {
        Import-Module $NTFSModule -force
        write-host 'Module' $ADModule 'loaded successfully'

    }
    
$DFSModule ='DFSN'
    if (Get-Module -Name $DFSModule) {
        write-host 'Module' $DFSModule 'already loaded'
    }
    else {
        Import-Module $DFSModule -force
        write-host 'Module' $DFSModule 'loaded successfully'

    }

#check if folder exists

if( -Not (Test-Path -Path "$newfolder" ) )
{
    #foldercreation
    New-Item -ItemType directory -Path "$folderpath"
    Write-Host "Folder $newfolder generated"
    #group creation
    
    New-ADGroup -Server $dc -GroupScope DomainLocal -Name ("acl_loc_folder_"+$newfolder+"_full") -Path "$ou"
    New-ADGroup -server $dc -GroupScope global -Name ("sec_glo_folder_"+$newfolder+"_full") -Path "$ou"
    $tempfullgroup = get-adgroup -server $dc -Identity ("sec_glo_folder_"+$newfolder+"_full")
    Add-ADGroupMember -Identity ("acl_loc_folder_"+$newfolder+"_full") -Members $tempfullgroup -Server $dc
    New-ADGroup -Server $dc -GroupScope DomainLocal -Name ("acl_loc_folder_"+$newfolder+"_read") -Path "$ou"
    New-ADGroup -server $dc -GroupScope global -Name ("sec_glo_folder_"+$newfolder+"_read") -Path "$ou"
    $tempreadgroup = get-adgroup -server $dc -Identity ("sec_glo_folder_"+$newfolder+"_read")
    Add-ADGroupMember -Identity ("acl_loc_folder_"+$newfolder+"_read") -Members $tempreadgroup -Server $dc
    #disable inheritance
    $acl = Get-Acl "$folderpath"
    $acl.SetAccessRuleProtection($true,$false)
    $acl | set-acl

    #adding ntfspermissions
    Write-Host "Adding NTFS Permissions"
    $folderpath | Set-NTFSOwner -Account "$domainadmin"
    Write-Host "New Owner auf $NewFolder is $domainadmin "
    Write-Host "Addin other NTFS Permissions on $NewFolder "
    Start-Sleep -Seconds 20
    Add-NTFSAccess -Path "$folderpath" -Account ("acl_loc_folder_"+$newfolder+"_read") -AccessRights Read,ReadAndExecute,ListDirectory
    Add-NTFSAccess -Path "$folderpath" -Account ("acl_loc_folder_"+$newfolder+"_full") -AccessRights Read,ReadAndExecute,ReadExtendedAttributes,ReadAttributes,DeleteSubdirectoriesAndFiles,Write,WriteAttributes,ListDirectory,CreateDirectories,CreateFiles 
    Add-NTFSAccess -Path "$folderpath" -Account "domain admins" -AccessRights FullControl
    Add-NTFSAccess -Path "$folderpath" -Account "SYSTEM" -AccessRights FullControl
    Add-NTFSAccess -Path "$folderpath" -Account "OWNER RIGHTS" -AccessRights Modify -AppliesTo SubfoldersAndFilesOnly
    Get-NTFSAccess -Path $folderpath -Account ("acl_loc_folder_"+$newfolder+"_full") | fl 
    Get-NTFSAccess -Path $folderpath -Account ("acl_loc_folder_"+$newfolder+"_read") | fl
}

else 
{

    Write-Host "$newfolder already exists, nothings done!"
    exit
}
$NewFolder = $null
$folderpath = $null
pause
