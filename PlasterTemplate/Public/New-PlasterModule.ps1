function Get-ValidValues {
    [CmdletBinding()]
    param(
        $Path
    )

    (Get-ChildItem -Path $Path -Directory).Name
}
Function New-PlasterModule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ModuleName,

        [Parameter(Mandatory)]
        [ArgumentCompleter( {
                param($Command, $Parameter, $WordToComplete, $CommandAst, $FakeBoundParams)

                Get-ValidValues -Path (Resolve-Path -Path "$PSScriptRoot\..\PlasterTemplates")
            })]
        [ValidateScript( {$_ -in (Get-ValidValues -Path (Resolve-Path -Path "$PSScriptRoot\..\PlasterTemplates"))} )]
        [string]
        $TemplatePath,

        [Parameter()]
        [string]
        $DestinationFolder = "$env:HOME\Documents\GitHub",

        [Parameter()]
        [string]
        $GitHubUserName = 'sk82jack'
    )

    Process {
        $ModulePath = Join-Path -Path $DestinationFolder -ChildPath $ModuleName
        Write-Verbose "Creating module folder: $ModulePath"
        New-Item -Path $ModulePath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

        $PlasterTemplatePath = Resolve-Path -Path "$PSScriptRoot\..\PlasterTemplates"
        $ModuleTemplatePath = Join-Path -Path $PlasterTemplatePath -ChildPath $TemplatePath
        Write-Verbose "Invoke-Plaster: Templatepath '$ModuleTemplatePath' DestinationPath '$ModulePath'"
        Invoke-Plaster -TemplatePath $ModuleTemplatePath -DestinationPath $ModulePath
        Set-Location $ModulePath
        git init
        git add .
        git commit -m 'Initial commit'
        git remote add origin "https://github.com/$GitHubUserName/$ModuleName.git"
        "Create an empty repo on Github called '$ModuleName' and then run the command 'git push -u origin master'"
    }
}
