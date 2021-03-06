###############################################################################
# SharePoint Solution Deployer (SPSD) Extension for Resetting files to their SiteDefinition
# Version          : 5.0.4.6440
# Url              : http://spsd.codeplex.com
# Creator          : René Hézser
# License          : MS-PL
# File             : ReGhost.ps1
###############################################################################

function Execute-ReGhostExtension($parameters, [System.Xml.XmlElement]$data, [string]$extId, [string]$extensionPath){
	$reGhostNode = $data.FirstChild
	$gc = Start-SPAssignment
	
	foreach($fileNode in $reGhostNode.ChildNodes){
		if ($fileNode.LocalName -ne 'File') { continue }
		
		if ([String]::IsNullOrEmpty($fileNode.AbsoluteWebUrl) -or [String]::IsNullOrEmpty($fileNode.WebRelativePath)) {
			Log -message ('Execute-FeaturesExtension: The AbsoluteWebUrl and WebRelativePath attributes must not be null') -type $SPSD.LogTypes.Error
			continue
		}

		Execute-ReghostAction $fileNode.AbsoluteWebUrl $fileNode.WebRelativePath $gc
	}
	
	$gc | Stop-SPAssignment
}

function Execute-ReghostAction ([string]$absoluteWebUrl, [string]$webRelativePath, $gc) {
	Log -message ('Resetting "'+[System.IO.Path]::GetFileName($webRelativePath)+'" to SiteDefinition...') -type $SPSD.LogTypes.Normal
	
	$web = Get-SPWeb -Identity $absoluteWebUrl
	if ($web -eq $null) {
			Log -message "Error. The Site does not exist" -type $SPSD.LogTypes.Error -NoIndent
	}
	$siteRelativeFileUrl = $absoluteWebUrl.TrimEnd('/')+'/'+$webRelativePath.TrimStart('/')
	$file = $web.GetFile($siteRelativeFileUrl);
	ReGhostFile($file)
}

function ReGhostFile([Microsoft.SharePoint.SPFile]$file) {
	if ($file.Exists) {
		if ($file.CustomizedPageStatus -eq [Microsoft.SharePoint.SPCustomizedPageStatus]::Customized) {
			$status = $file.CheckOutType
			if ($status -ne [Microsoft.SharePoint.SPFile+SPCheckOutType]::None) {
				Log -message 'The file is checked out' -type $SPSD.LogTypes.Warning -NoIndent
			} else {
				$file.RevertContentStream()
				Log -message 'Done' -type $SPSD.LogTypes.Success -NoIndent
			}
		} else {
			Log -message 'Done (already ghosted)' -type $SPSD.LogTypes.Success -NoIndent
		}
	} else {
		Log -message 'File does not exist' -type $SPSD.LogTypes.Warning -NoIndent
	}
}