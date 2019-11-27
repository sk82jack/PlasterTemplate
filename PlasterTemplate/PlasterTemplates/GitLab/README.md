[![pipeline status](<%= $PLASTER_PARAM_GitLabURL %>/<%= $PLASTER_PARAM_GitLabUserName %>/<%= $PLASTER_PARAM_ModuleName %>/badges/master/pipeline.svg)](<%= $PLASTER_PARAM_GitLabURL %>/<%= $PLASTER_PARAM_GitLabUserName %>/<%= $PLASTER_PARAM_ModuleName %>/commits/master)
[![coverage report](<%= $PLASTER_PARAM_GitLabURL %>/<%= $PLASTER_PARAM_GitLabUserName %>/<%= $PLASTER_PARAM_ModuleName %>/badges/master/coverage.svg)](<%= $PLASTER_PARAM_GitLabURL %>/<%= $PLASTER_PARAM_GitLabUserName %>/<%= $PLASTER_PARAM_ModuleName %>/commits/master)
# <%= $PLASTER_PARAM_ModuleName %>

<%= $PLASTER_PARAM_ModuleDesc %>

## Description

<%= $PLASTER_PARAM_ModuleDesc %>

Authored by <%= $PLASTER_PARAM_FullName %>

## Installing

<%
    if ($PLASTER_PARAM_PSRepository -eq 'CustomRepo') {
@"
### Installing the PowerShell Repository

You will need to install the PowerShell Repository in order to download this module. If you have previously installed a module from the PowerShell Repository then you can skip this step and install the module.

To do this run the following command.
``````
Register-PSRepository -Name 'InternalRepo' -SourceLocation '$PLASTER_PARAM_PSRepositoryURL' -InstallationPolicy Trusted
``````

To verify the repository has installed correctly open a PowerShell prompt and run the command `Get-PSRepository`. You should see the InternalRepo in the output similar to below.

`````` PowerShell
Name                      InstallationPolicy   SourceLocation
----                      ------------------   --------------
PSGallery                 Untrusted            https://www.powershellgallery.com/api/v2/
InternalRepo              Trusted              $PLASTER_PARAM_PSRepositoryURL
``````

"@
    }
%>
### Installing the module

You can install it using:

``` PowerShell
PS> Install-Module -Name <%= $PLASTER_PARAM_ModuleName %>
```

### Updating <%= $PLASTER_PARAM_ModuleName %>

Once installed from the PowerShell Gallery, you can update it using:

``` PowerShell
PS> Update-Module -Name <%= $PLASTER_PARAM_ModuleName %>
```

### Uninstalling <%= $PLASTER_PARAM_ModuleName %>

To uninstall <%= $PLASTER_PARAM_ModuleName %>:

``` PowerShell
PS> Uninstall-Module -Name <%= $PLASTER_PARAM_ModuleName %>
```

## Contributing to <%= $PLASTER_PARAM_ModuleName %>

Interested in contributing? Read how you can [Contribute](Contributing.md) to <%= $PLASTER_PARAM_ModuleName %>

## Release History

A detailed release history is contained in the [Change Log](CHANGELOG.md).

## License

<%= $PLASTER_PARAM_ModuleName %> is provided under the [MIT license](LICENSE).
