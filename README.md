# PlasterTemplate
Personal Plaster templates

## How to use
Import the module and then run the only function in the module `New-PlasterModule`

There are 3 parameters:

**ModuleName** - This is the name of the module

**OutPath** - This is the folder in which to create your new module (do not include the ModuleName folder - this is added and created automatically)

**TemplateName** - This is a tab-completable parameter to choose the particular plaster template

Here is an example:
```
New-PlasterModule -ModuleName TestModule -OutPath C:\temp\ -TemplateName GitLab
```

You will then be prompted with the Plaster questions. Here's an example of some questions and responses:
```
  ____  _           _
 |  _ \| | __ _ ___| |_ ___ _ __
 | |_) | |/ _` / __| __/ _ \ '__|
 |  __/| | (_| \__ \ ||  __/ |
 |_|   |_|\__,_|___/\__\___|_|
                                            v1.1.3
==================================================
Module author's name: Test Author
Module author's GitLab user account name: tauthor
Module author's GitLab email address: tauthor@test.com
The URL of the GitLab server: https://gitlab.test.com
Name of your module: TestModule
Brief description on this module: Test module
Do you want to deploy to a custom repository or the PSGallery?
[C] Custom repository  [P] PSGallery  [?] Help (default is "C"): c
Enter the URL for the custom repository: http://proget.test.com
Do you want to deploy docs with mkDocs?
[No] Do not deploy docs with mkDocs [Yes] Deploy docs with mkDocs [?] Help (default is "No"): yes
```

Note: If you choose to deploy docs with mkDocs, you will need to ensure that your GitLab-CI running has access to a Personal Access Token via a variable.


At this point it will create your module.

Following the module creation you will need to do the following steps:

1. Create the repository on the Git server using the module name specified
2. Add the PowerShell repository API key to your repository environment variables as the name `NugetAPIKey`
3. cd into the directory of your new module and run `git push -u origin master` to push the initial commit up to the Git server

To create a deployment you need to tag a commit with the release version and then push that tag to the git server. So, if you were deploying version 0.1.0 you would do the following:
```ps
git tag 0.1.0
git push origin 0.1.0
```
To view the coverage report as a badge in the readme, you need to update your "Test coverage parsing" setting at Settings > CI/CD > General pipelines for your repository.
<!-- Add recommended regex settings for "'/^Covered (\d+.\d+\%) of \d+ analyzed Commands in \d+ Files\.$/'" here. -->
