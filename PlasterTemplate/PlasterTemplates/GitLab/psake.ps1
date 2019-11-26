# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    if (-not $ENV:BHProjectPath) {
        $ENV:BHProjectPath = Resolve-Path "$PSScriptRoot\.."
    }
    $PSVersion = $PSVersionTable.PSVersion.Major
    $lines = '----------------------------------------------------------------------'
    $Verbose = @{}
    if ($ENV:BHCommitMessage -match "!verbose") {
        $Verbose = @{Verbose = $True}
    }
    $PSRepository = '<%= $PLASTER_PARAM_PSRepository %>'

    git config user.email 'pipeline@example.com'
    git config user.name 'pipeline'
}

Task Default -Depends Test

Task Init {
    $lines
    Set-Location $ENV:BHProjectPath
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"
}

Task Test -Depends Init {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Testing links on GitLab requires >= tls 1.2
    $SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Gather test results
    $TestFile = "TestResults.xml"
    $CoverageFile = "TestCoverage.xml"
    $CodeFiles = (Get-ChildItem $ENV:BHModulePath -Recurse -Include "*.psm1", "*.ps1").FullName
    $Params = @{
        Path                   = "$ENV:BHProjectPath\Tests"
        OutputFile             = "$ENV:BHProjectPath\$TestFile"
        OutputFormat           = 'NUnitXml'
        CodeCoverage           = $CodeFiles
        CodeCoverageOutputFile = "$ENV:BHProjectPath\$CoverageFile"
        Show                   = 'Fails'
        PassThru               = $true
    }
    $TestResults = Invoke-Pester @Params
    [Net.ServicePointManager]::SecurityProtocol = $SecurityProtocol

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends Test {
    $lines
    "`n"

    # Compile seperate ps1 files into the psm1
    $Stringbuilder = [System.Text.StringBuilder]::new()
    $Folders = Get-ChildItem -Path $env:BHModulePath -Directory
    foreach ($Folder in $Folders.Name) {
        [void]$Stringbuilder.AppendLine("Write-Verbose 'Importing from [$env:BHModulePath\$Folder]'" )
        if (Test-Path "$env:BHModulePath\$Folder") {
            $Files = Get-ChildItem "$env:BHModulePath\$Folder\*.ps1"
            if ($Folder -eq 'Public') {
                $PublicFunctions = $Files.BaseName
            }
            foreach ($File in $Files) {
                $Name = $File.Name
                "`tImporting [.$Name]"
                [void]$Stringbuilder.AppendLine("# .$Name")
                [void]$Stringbuilder.AppendLine([System.IO.File]::ReadAllText($File.fullname))
            }
        }
        "`tRemoving folder [$env:BHModulePath\$Folder]"
        Remove-Item -Path "$env:BHModulePath\$Folder" -Recurse -Force
    }
    $ModulePath = Join-Path -Path $env:BHModulePath -ChildPath "$env:BHProjectName.psm1"
    "`tCreating module [$ModulePath]"
    Set-Content -Path $ModulePath -Value $Stringbuilder.ToString()

    # Load the module, read the exported functions & aliases, update the psd1 FunctionsToExport & AliasesToExport
    "`tSetting module functions"
    Set-ModuleFunctions -FunctionsToExport $PublicFunctions
    "`tSetting module aliases"
    Set-ModuleAliases

    # Set the module version from the release tag
    "`tUpdating the module manifest with the new version number"
    [version]$ReleaseVersion = git describe --tags
    $GalleryVersion = Find-Package -Name $env:BHProjectName -Source $PSRepository -ProviderName 'NuGet' -ErrorAction Stop
    if ($ReleaseVersion -le [version]$GalleryVersion.Version) {
        Write-Error "Gallery version is higher than or equal to the release version. The release version must be increased"
    }
    Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $ReleaseVersion -ErrorAction stop
    "`n"
}

Task BuildDocs -depends Build {
    $lines
    "`n`tImporting the module and start building the yaml"
    "`t`tImporting from '$env:BHPSModuleManifest'"
    Import-Module -Name $env:BHPSModuleManifest -Global -Force
    $DocFolder = "$env:BHProjectPath\docs"
    $YMLtext = (Get-Content "$env:BHProjectPath\header-mkdocs.yml") -join "`r`n"
    $YMLtext = "$YMLtext`r`n  - Change Log: ChangeLog.md`r`n"
    $YMLText = "$YMLtext  - Functions:`r`n"

    "`tRemoving old documentation"
    $parameters = @{
        Recurse     = $true
        Force       = $true
        Path        = "$DocFolder\functions"
        ErrorAction = 'SilentlyContinue'
    }
    $null = Remove-Item @parameters

    "`tBuilding documentation"
    if (!(Test-Path $DocFolder)) {
        New-Item -Path $DocFolder -ItemType Directory
    }
    $Params = @{
        Module       = $ENV:BHProjectName
        Force        = $true
        OutputFolder = "$DocFolder\functions"
        NoMetadata   = $true
    }
    New-MarkdownHelp @Params | foreach-object {
        $Function = $_.Name -replace '\.md', ''
        $Part = "    - {0}: functions/{1}" -f $Function, $_.Name
        $YMLText = "{0}{1}`n" -f $YMLText, $Part
        $Part
    }
    $YMLtext | Set-Content -Path "$env:BHProjectPath\mkdocs.yml"
    Copy-Item -Path "$env:BHProjectPath\README.md" -Destination "$DocFolder\index.md" -Force

    [version]$ReleaseVersion = git describe --tags

    $ChangeLogData = Get-ChangeLogData
    if (-not ($ChangeLogData.Unreleased.Data.psobject.properties.value -ne '')) {
        Write-Error 'Cannot perform a deploy without updating the changelog'
    }

    $Params = @{
        Path           = "$env:BHProjectPath\CHANGELOG.md"
        ReleaseVersion = $ReleaseVersion.ToString()
        LinkMode       = 'Automatic'
        LinkPattern    = @{
            FirstRelease  = "https://gitlab.com/<%= $PLASTER_PARAM_GitLabUserName %>/$env:BHProjectName/tree/v{CUR}"
            NormalRelease = "https://gitlab.com/<%= $PLASTER_PARAM_GitLabUserName %>/$env:BHProjectName/compare/v{PREV}..v{CUR}"
            Unreleased    = "https://gitlab.com/<%= $PLASTER_PARAM_GitLabUserName %>/$env:BHProjectName/compare/v{CUR}..HEAD"
        }
    }
    Update-Changelog @Params
    Convertfrom-Changelog -Path "$env:BHProjectPath\CHANGELOG.md" -OutputPath "$DocFolder\ChangeLog.md" -Format 'Release'
    "`n"
}

Task TestAfterBuild -Depends BuildDocs {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results
    $Params = @{
        Path     = "$ENV:BHProjectPath\Tests"
        Show     = 'Fails'
        PassThru = $true
    }
    $TestResults = Invoke-Pester @Params

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if ($TestResults.FailedCount -gt 0) {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Deploy -Depends TestAfterBuild {
    $lines

    "`n`tTesting for PowerShell Gallery API key"
    if (-not $ENV:NugetApiKey) {
        Write-Error "PowerShell Gallery API key not found"
    }

    "`tTesting for GitLab Personal Access Token"
    if (!$ENV:GitLab_PAT) {
        Write-Error "GitLab personal access token not found"
    }

    # Register the ProGet repository if it's not already registered
    $InternalRepo = Get-PSRepository -Name InternalRepo -ErrorAction SilentlyContinue
    If ($InternalRepo) {
        $InternalRepo | Unregister-PSRepository
    }
    $RepositoryParams = @{
        'Name'               = 'InternalRepo'
        'SourceLocation'     = $PSRepository
        'PublishLocation'    = $PSRepository
        'InstallationPolicy' = 'Trusted'
    }
    "`nAdding repository '{0}'" -f $RepositoryParams.SourceLocation
    Register-PSRepository @RepositoryParams

    $Params = @{
        Path    = "$ENV:BHProjectPath\Build"
        Force   = $true
        Recurse = $false # We keep psdeploy artifacts, avoid deploying those : )
    }
    "`nInvoking PSDeploy"
    Invoke-PSDeploy @Verbose @Params

    "`tSetting git repository url"
    $GitLabUrl = 'https://{0}@gitlab.com/<%= $PLASTER_PARAM_GitLabUserName %>/{1}.git' -f $ENV:GitLab_PAT, $env:BHProjectName

    "`tPushing built docs to GitLab"
    git add "$env:BHProjectPath\docs\*"
    git add "$env:BHModulePath\mkdocs.yml"
    git add "$env:BHModulePath\CHANGELOG.md"
    git commit -m "Bump version to $ReleaseVersion`n[ci skip]"
    # --porcelain is to stop git sending output to stderr
    git push $GitLabUrl HEAD:master --porcelain
    "`n"
}
