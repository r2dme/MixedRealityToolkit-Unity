<#
.SYNOPSIS
    Prepares the MRTK\Examples folder for UPM packaging.
.DESCRIPTION
    Prepares the MRTK\Examples folder for UPM packaging.
#>

$examplesRoot = "$(Get-Location)"

# This hashtable contains mappings of the sample categories to the folder which contains
# the code and assets.
#
# Note that capitalization below in the key itself is significant.
#
# These paths are examplesRoot relative.
$exampleFolders = [ordered]@{
    "Demos" = "Demos";
    "Experimental" = "Experimental";
}

# Beginning of the upm packaging script main section
# The overall structure of this script is:
#
# 1) Create the required Samples~ folder
# 2) Recursively copy the contents of the example folders into Samples~
# 3) Prepare the samples entry for the package.json file
# 4) Replace the %samples% token with the prepared data
# 5) Overwrite the package.json file

# Ensure the required folder exists
$samplesFolder = "$examplesRoot\Samples~"
if (-not (Test-Path -Path $samplesFolder)) {
    New-Item $samplesFolder -ItemType Directory | Out-Null
}

# Copy each example folder
foreach ($entry in $exampleFolders.GetEnumerator()) {
    $sampleGroupName = $entry.Name
    Write-Output "Copying $examplesRoot\$sampleGroupName to $samplesFolder\$sampleGroupName"
    Copy-Item -Path "$examplesRoot\$sampleGroupName" -Destination "$samplesFolder\$sampleGroupName" -Recurse -Force
    Copy-Item -Path "$examplesRoot\$sampleGroupName.meta"-Destination "$samplesFolder\$sampleGroupName.meta"
}

# Create the samples data for the package.json file
$sampleCategoryCount = 0
$samples = "`"samples`": ["
foreach ($entry in $exampleFolders.GetEnumerator()) {
    # Since we need to place appropriate separator characters between entries, we need to
    # keep track of how many folders we have processed
    $sampleCategoryCount++

    $folderName = $entry.Name
    $subFolderList = Get-ChildItem -Path "$samplesFolder\$folderName" -Directory -Name
    $sampleCount = 0
    foreach ($n in $subFolderList) 
    {
        $sampleCount++

        $displayName = "$folderName - $n"
        $description = "MRTK Examples: $n ($folderName)"
        $path = "Samples~/$folderName/$n"
    
        $samples = $samples + "`n      {`n"
        $samples = $samples + "        `"displayName`": `"" + $displayName + "`",`n"
        $samples = $samples + "        `"description`": `"" + $description + "`",`n"
        $samples = $samples + "        `"path`": `"" + $path + "`"`n"
        $samples = $samples + "      }"
        if ($sampleCategoryCount -eq $exampleFolders.keys.count) {
            if (-not ($sampleCount -eq $subFolderList.count)) {
                $samples = $samples + ","
            }
        }
        else {
            $samples = $samples + ","
        }
        
    }
}
$samples = $samples + "`n   ]"

# Update the project.json file to specify the samples contanined in the package
$packageJsonPath = "$examplesRoot\package.json"
$packageJson = [System.IO.File]::ReadAllText($packageJsonPath)
$packageJson = ($packageJson -replace "%samples%", $samples)
Write-Output $packageJson
[System.IO.File]::WriteAllText($packageJsonPath, $packageJson)
