Function New-PlasterModule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $ModuleName,

        [Parameter()]
        [string]
        $OutPath
    )
    DynamicParam {
        # Set the dynamic parameters' name
        $ParameterName = 'TemplateName'

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
        $ProjectRoot = Resolve-Path "$PSScriptRoot\.."
        $ModuleTemplatePath = Join-Path -Path $ProjectRoot -ChildPath 'PlasterTemplates'
        $PlasterTemplates = Get-ChildItem -Path $ModuleTemplatePath -Directory
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($PlasterTemplates.Name)

        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)

        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    Begin {
        # Bind the parameter to a friendly variable
        $ModuleTemplate = Join-Path -Path $ModuleTemplatePath -ChildPath $PsBoundParameters[$ParameterName]
    }
    Process {
        $ModulePath = Join-Path -Path $OutPath -ChildPath $ModuleName
        Write-Verbose "Creating module folder: $ModulePath"
        $null = New-Item -Path $ModulePath -ItemType 'Directory' -Force
        Write-Verbose "Invoke-Plaster: Templatepath '$ProjectRoot\PlasterTemplates\$TemplateName' DestinationPath '$OutPath\$ModuleName'"
        Invoke-Plaster -TemplatePath $ModuleTemplate -DestinationPath $ModulePath
        Push-Location -Path $ModulePath
        . .\gitinit.ps1
        Remove-Item -Path '.\gitinit.ps1'
        gitinit
        Remove-Item -Path Function:\gitinit
        Pop-Location

        ''
        $Message = "Module created at $ModulePath"
        Write-Host $Message -ForegroundColor Green
        $Message = "Now create an empty repo on the Git server called '$ModuleName' and then run the command 'git push -u origin master'"
        Write-Host $Message -ForegroundColor Yellow
    }
}
