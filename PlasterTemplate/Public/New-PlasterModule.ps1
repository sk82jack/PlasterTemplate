Function New-PlasterModule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        [string]
        $ModuleName,

        [Parameter()]
        [string]
        $DestinationFolder = "$env:HOME\Documents\GitHub",

        [Parameter()]
        [string]
        $GitHubUserName = 'sk82jack'
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'TemplatePath'

        # Create the dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        # Create the collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]

        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $true
        $ParameterAttribute.Position = 1

        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)

        # Generate and set the ValidateSet
        $Script:ProjectRoot = Resolve-Path "$PSScriptRoot\.."
        $PlasterTemplatePath = Join-Path -Path $ProjectRoot -ChildPath 'PlasterTemplates'
        $PlasterTemplates = Get-ChildItem -Path $PlasterTemplatePath -Directory
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($PlasterTemplates.Name)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    Begin {
        # Bind the parameter to a friendly variable
        $TemplatePath = $PsBoundParameters[$ParameterName]
    }
    Process {
        $ModulePath = Join-Path -Path $DestinationFolder -ChildPath $ModuleName
        Write-Verbose "Creating module folder: $ModulePath"
        New-Item -Path $ModulePath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

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
