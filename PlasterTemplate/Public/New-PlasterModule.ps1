Function New-PlasterModule {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        $ModuleName,

        [Parameter()]
        [string]
        $DestinationFolder = "D:\PSModules"
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
        $PlasterTemplates = Get-ChildItem -Path "$ProjectRoot\PlasterTemplates" -Directory
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
        Write-Verbose "Creating module folder: $DestinationFolder\$ModuleName"
        New-Item -Path "$DestinationFolder\$ModuleName" -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        Write-Verbose "Invoke-Plaster: Templatepath '$ProjectRoot\PlasterTemplates\$TemplatePath' DestinationPath '$DestinationFolder\$ModuleName'"
        Invoke-Plaster -TemplatePath "$ProjectRoot\PlasterTemplates\$TemplatePath" -DestinationPath "$DestinationFolder\$ModuleName"
        Set-Location "$DestinationFolder\$ModuleName"
        git init
        git add .
        git commit -m 'Initial commit'
        git remote add origin "https://github.com/sk82jack/$ModuleName.git"
        "Create an empty repo on Github called '$ModuleName' and then run the command 'git push -u origin master'"
    }
}