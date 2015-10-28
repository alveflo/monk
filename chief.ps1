<#
  .SYNOPSIS
    Watches file system and copies from src -> dest on file change
  .PARAMETER SourcePath
  	Path to source
  .PARAMETER DestPath
  	Path to destination
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

Function Watch($SourcePath, $DestPath, $IncludeSubDirectories) {
	try{
	  $watcher = New-Object IO.FileSystemWatcher $SourcePath -Property @{
	    IncludeSubDirectories = $IncludeSubDirectories
	    NotifyFilter = [IO.NotifyFilters] 'FileName, LastWrite'
	  }

	  $delegate = {
	    $name = $Event.SourceEventArgs.Name
			$path = $Event.SourceEventArgs.FullPath
	    $changeType = $Event.SourceEventArgs.ChangeType
			$conf = $Event.MessageData

	    Write-Host "[$(Get-Date -Format 'HH:mm:ss')]: " -Foreground DarkGray -NoNewLine
	    switch ($changeType)
	    {
	      'Created' { Write-Host "$changeType " -Foreground Green    -NoNewLine }
	      'Changed' { Write-Host "$changeType " -Foreground Cyan     -NoNewLine }
	      'Renamed' { Write-Host "$changeType " -Foreground Yellow   -NoNewLine }
	      'Deleted' { Write-Host "$changeType " -Foreground Red      -NoNewLine }
	    }
	    Write-Host $path.Replace($conf.src, '') -Foreground DarkCyan -NoNewLine
	    if ($changeType -ne 'Deleted') {
				$destinationFile = Join-Path $conf.dest $path.Replace($conf.src, '')
				$destinationPath = Join-Path $conf.dest $path.Replace($conf.src, '').Replace($name, '')
				if (-not (Test-Path $destinationPath)) {
					New-Item -ItemType Directory -Path $destinationPath
				}
	      Copy-Item $path $destinationFile
				Write-Host " (-> $destinationFile)" -Foreground DarkGray -NoNewLine
	    }
			Write-Host
	  }

		$config = New-Object PSObject -Property @{src = $SourcePath; dest = $DestPath}
		Write-Host $config
	  $fileCreated  = Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action $delegate -MessageData $config
	  $fileChanged  = Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action $delegate -MessageData $config
	  $fileRenamed  = Register-ObjectEvent $watcher Renamed -SourceIdentifier FileRenamed -Action $delegate -MessageData $config
	  $fileDeleted  = Register-ObjectEvent $watcher Deleted -SourceIdentifier FileDeleted -Action $delegate -MessageData $config


    cls
    Write-Host "`n`n`tAhoy!" -Foreground Green -NoNewLine
    Write-Host "`n`n`tI'm watchin' your file system, chief!`n`tYou know the drill, press Ctrl+C to cancel.`n`n"
    while($true){}
  } catch {
		throw $_.Exception
	} finally {
    Write-Host "`n`n`tUnregistering events..."
    Unregister-Event FileCreated
    Unregister-Event FileChanged
    Unregister-Event FileDeleted
    Unregister-Event FileRenamed
    Write-Host "`tDone. Later!`n`n"
  }
}

Watch $SourcePath $DestPath $IncludeSubDirectories
