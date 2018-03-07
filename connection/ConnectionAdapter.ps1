Class Connection
{
    [string] $dbName = $null;
    [XML] $config;
    #[string] $ENV_TYPE;
    [int] getMaxNumberOfItteration()    
    {
        return 1000;
    }
    Connection()
    {
        $this.config = Get-Content -Encoding UTF9 $PSScriptRoot\config.xml
       # $this.$ENV_TYPE = $this.config.CT_CONFIG.TYPE
    }

    [System.Object] directConnectionToHana($ScriptName)
    {
        
    }
}



