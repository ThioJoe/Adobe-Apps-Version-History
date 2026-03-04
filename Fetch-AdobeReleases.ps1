# Fetch-AdobeReleases.ps1
$ProgressPreference = 'SilentlyContinue'

$excludedIds = @("VC10win32", "VC10win64", "VC11win32", "VC11win64", "VC14win64")

$endpointUrl = $env:ADOBE_ENDPOINT_URL
if ([string]::IsNullOrWhiteSpace($endpointUrl)) {
    Write-Error "ADOBE_ENDPOINT_URL environment variable is not set."
    exit 1
}

$headers = @{
    "content-type" = "application/json"
    "x-adobe-app-id" = $env:ADOBE_APP_ID
    "x-api-key" = $env:ADOBE_API_KEY
}

Write-Host "Fetching data from endpoint..."
$response = Invoke-WebRequest -Uri $endpointUrl -Method POST -Headers $headers -UseBasicParsing

Write-Host "Parsing XML..."
[xml]$xmlDoc = $response.Content

$productsMap = @{}

# Extract services and products using local-name() to bypass potential XML namespace issues
$productNodes = $xmlDoc.SelectNodes("//*[local-name()='service' or local-name()='product']")
foreach ($node in $productNodes) {
    $id = $node.GetAttribute("id")
    if ([string]::IsNullOrWhiteSpace($id)) { continue }
    
    $displayName = $id
    $dnNode = $node.SelectSingleNode("*[local-name()='displayName']")
    if ($dnNode) {
        $displayName = $dnNode.InnerText
    } elseif ($node.HasAttribute("displayName")) {
        $displayName = $node.GetAttribute("displayName")
    }

    if (-not $productsMap.ContainsKey($id)) {
        $productsMap[$id] = @{
            id = $id
            displayName = $displayName
            builds = @()
        }
    }
}

# Extract and map builds
$buildNodes = $xmlDoc.SelectNodes("//*[local-name()='build']")
foreach ($b in $buildNodes) {
    $buildId = $b.GetAttribute("id")
    if ([string]::IsNullOrWhiteSpace($buildId)) { continue }

    $version = $b.GetAttribute("version")
    if ([string]::IsNullOrWhiteSpace($version)) {
        $appVerNode = $b.SelectSingleNode("*[local-name()='appVersion']")
        if ($appVerNode) { $version = $appVerNode.InnerText } else { $version = "N/A" }
    }

    $platform = $b.GetAttribute("platform")
    if ([string]::IsNullOrWhiteSpace($platform)) { $platform = "unknown" }

    $goLive = $b.GetAttribute("goLiveTime")
    
    $type = $b.GetAttribute("type")
    if ([string]::IsNullOrWhiteSpace($type)) { $type = "N/A" }

    $buildObj = @{
        buildId = $buildId
        version = $version
        platform = $platform
        goLive = $goLive
        type = $type
    }

    $appId = $buildId
    if ($buildId.Contains("_")) {
        $appId = $buildId.Split("_")[0]
    }

    if ($productsMap.ContainsKey($appId)) {
        $productsMap[$appId].builds += $buildObj
    } else {
        $productsMap[$appId] = @{
            id = $appId
            displayName = $appId
            builds = @($buildObj)
        }
    }
}

Write-Host "Saving structured data..."
$outDir = Join-Path (Get-Location).Path "data"
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

foreach ($appKey in $productsMap.Keys) {
    $app = $productsMap[$appKey]
    $cleanId = $app.id -replace '[^a-zA-Z0-9_-]', ''
    if ([string]::IsNullOrWhiteSpace($cleanId)) { continue }
    
    if ($excludedIds -contains $cleanId) { continue }
    
    $outPath = Join-Path $outDir "$cleanId.json"
    
    if (Test-Path $outPath) {
        $existingJson = Get-Content -Path $outPath -Raw -Encoding UTF8
        $existingApp = ConvertFrom-Json $existingJson
        
        $existingBuildIds = @{}
        if ($null -ne $existingApp.builds) {
            foreach ($b in $existingApp.builds) {
                if ($null -ne $b.buildId) {
                    $existingBuildIds[$b.buildId] = $true
                }
            }
        }
        
        $mergedBuilds = @()
        if ($null -ne $existingApp.builds) {
            $mergedBuilds += @($existingApp.builds)
        }
        
        foreach ($newBuild in $app.builds) {
            if (-not $existingBuildIds.ContainsKey($newBuild.buildId)) {
                $mergedBuilds += $newBuild
            }
        }
        
        $app.builds = $mergedBuilds
    }
    
    # Convert object to JSON. Depth 10 accommodates nested build arrays.
    $json = ConvertTo-Json -InputObject $app -Depth 10 -Compress:$false
    
    # Write as BOM-less UTF8 to avoid Git formatting issues
    [System.IO.File]::WriteAllText($outPath, $json, [System.Text.Encoding]::UTF8)
}

Write-Host "Data successfully separated by app and saved to the 'data' directory."