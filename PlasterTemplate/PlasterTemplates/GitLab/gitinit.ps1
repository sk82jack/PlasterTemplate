function gitinit {
    git init
    git add .
    git commit -m 'Initial commit'
    git remote add origin <%= $PLASTER_PARAM_GitLabURL %>/<%= $PLASTER_PARAM_GitLabUserName %>/<%= $PLASTER_PARAM_ModuleName %>
}
