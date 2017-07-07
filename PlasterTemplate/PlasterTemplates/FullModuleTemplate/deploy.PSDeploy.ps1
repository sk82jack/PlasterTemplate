if ($ENV:BHProjectName -and $ENV:BHProjectName.Count -eq 1) {
    Deploy Module {
        By PSGalleryModule {
            FromSource $ENV:BHModulePath
            To PHETestRepository
            WithOptions @{
                ApiKey = $ApiKey
            }
        }
    }
}