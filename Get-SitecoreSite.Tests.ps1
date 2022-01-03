Describe 'Get-SitecoreSite.Tests' {
    It 'passes empty' {
        . ./Get-SitecoreSite.ps1
        Get-SitecoreSite | Should -Not -BeNullOrEmpty #IF SITECORE SITES EXIST IN WWWROOT
        $? | Should -Be $true
    }
    It 'passes bad' {
        . ./Get-SitecoreSite.ps1
        {Get-SitecoreSite bad} | Should -Throw
    }
    It 'passes site' {
        . ./Get-SitecoreSite.ps1
        $results = Get-SitecoreSite 'sitecore.sc'
        $results | Should -Not -BeNullOrEmpty
        $results | Should -BeLike '*sitecore.sc'
    }
    It 'passes wildcard' {
        . ./Get-SitecoreSite.ps1
        $results = Get-SitecoreSite 'sxp*' -verbose
        $results | Should -Not -BeNullOrEmpty
    }
    #It 'passes iis' {
    #    . ./Get-SitecoreSite.ps1
    #    $results = Get-SitecoreSite 'sxp*' -mode 'iis' -verbose
    #    $results | Should -Not -BeNullOrEmpty
        #Error: Cannot read configuration file due to insufficient permissions
    #}
}