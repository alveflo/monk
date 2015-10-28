<#
  .SYNOPSIS
    Copies role/profile permissions permissions from template.
  .PARAMETER TemplateUrl
  	Relative url to the template web
  .PARAMETER RoleName
  	Name of the role
  .PARAMETER RoleType
  	Type of the role, provided as 'role' or 'profile'.
  .PARAMETER AllWebs
  	Flag to copy permissions to all webs on product
  .PARAMETER WebsList
  	Comma separated file containing webs to copy to
	.EXAMPLE
	CopyPermission
		-TemplateUrl url
			-Roles .\roles.txt = { RoleName;IsProfile }
		||  -AllRoles
			-AllWebs
		||  - WebLists .\webList.txt = { Urls }
		-CreateProfilesIfNotExists
#>

param (
	[parameter(Mandatory=$true)]
  [alias('s')]
	[ValidateScript({ Test-Path $_ })]
	[string]$SourcePath,
	[parameter(Mandatory=$true)]
  [alias('d')]
	[string]$DestPath,
  [switch]$IncludeSubDirectories
)

Function Watch($src, $dest, $includeSubDirectories) {
  $watcher = New-Object IO.FileSystemWatcher $src -Property @{
    IncludeSubDirectories = $includeSubDirectories
    NotifyFilter = [IO.NotifyFilters] 'FileName, LastWrite'
  }

  $delegate = {
    $name = $Event.SourceEventArgs.Name
    $changeType = $Event.SourceEventArgs.ChangeType
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] - $name : Changetype: $changeType"
  }

  $fileCreated  = Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action $delegate
  $fileChanged  = Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action $delegate
  $fileRenamed  = Register-ObjectEvent $watcher Renamed -SourceIdentifier FileRenamed -Action $delegate
  $fileDeleted  = Register-ObjectEvent $watcher Deleted -SourceIdentifier FileDeleted -Action $delegate

  try{
    Write-Host "Running"
    while($true){}
  }
  finally {
    Write-Host "Unregistering events..."
    Unregister-Event FileCreated
    Unregister-Event FileChanged
    Unregister-Event FileDeleted
    Unregister-Event FileRenamed
    Write-Host "Done."
  }
}

Watch $SourcePath $DestPath $IncludeSubDirectories
