configuration NanoClusterS2D {
<#
    .SYNOPSIS
        Creates a Storage Spaces Direct cluster.
#>
    param (
        ## Name of the failover cluster/node (FQDN) to enable S2D on.
        [Parameter(Mandatory)]
        [System.String] $ClusterName,

        ## Credential used to create the cluster
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,

        ## Indicates that the pool should be automatically created and configured. When a pool already exists before
        ## S2D is enabled the AutoConfig parameter becomes a no-op. AutoConfig is set to true by default. If you do
        ## not want the pool to be automatically created, but created manually, you should set AutoConfig to false.
        [Parameter()]
        [System.Boolean]
        $AutoConfig = $true,

        ## Specifies the friendly name of the S2D pool when it is created.
        [Parameter()]
        [System.String]
        $PoolFriendlyName,

        ## Specifies the S2D cache state. The default value is Enabled.
        [Parameter()]
        [ValidateSet('Enabled','Disabled')]
        [System.String] $CacheState = 'Enabled',
        
        ## Indicates that this cmdlet skips cache eligibility checks.
        [Parameter()]
        [System.Boolean]
        $SkipEligibilityChecks

        #[Parameter()]
        #[ValidateSet('Present','Absent')]
        #[System.String] $Ensure = 'Present'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Script "NanoClusterS2D$($ClusterName.Replace('.',''))" {

        GetScript = {

            if (-not (Get-Module -Name FailoverClusters -ListAvailable))
            {
                throw ("Missing 'FailoverClusters' module.");
            }

            $clusterS2D = Get-ClusterStorageSpacesDirect -CimSession $using:ClusterName -ErrorAction SilentlyContinue;

            return @{ Result = $clusterS2D.State; }

        } #end GetScript

        TestScript = {

            try
            {
                if (-not (Get-Module -Name FailoverClusters -ListAvailable))
                {
                    throw ("Missing 'FailoverClusters' module.");
                }
                elseif (-not ($using:ClusterName).Contains('.'))
                {
                    Write-Warning -Message ("Cluster name should be specified as a FQDN");
                }

                $clusterS2D = Get-ClusterStorageSpacesDirect -CimSession $using:ClusterName -ErrorAction SilentlyContinue;

                if ($null -eq $clusterS2D)
                {
                    Write-Verbose -Message ("Cluster S2D configuration not found.");
                    return $false;
                }
                elseif ($clusterS2D.CacheState -ne $using:CacheState)
                {
                    Write-Verbose -Message ("Cluster S2D configuration not {0}." -f ($using:CacheState).ToLower());
                    return $false;
                }

                return $true;

            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction Stop;
            }

        } #end TestScript

        SetScript = {

            $clusterS2D = Get-ClusterStorageSpacesDirect -CimSession $using:ClusterName -ErrorAction SilentlyContinue;

            if ($clusterS2D.State -ne 'Enabled')
            {
                Write-Verbose -Message ("Enabling S2D on cluster '{0}'." -f $using:ClusterName);
                Enable-ClusterStorageSpacesDirect -CimSession $using:ClusterName -CacheState $using:CacheState -Confirm:$false;
            }
            else
            {
                Write-Verbose -Message ("Updating S2D on cluster '{0}'." -f $using:ClusterName);
                Set-ClusterStorageSpacesDirect -CimSession $using:ClusterName -CacheState $using:CacheState;
            }

        } #end SetScript

        PsDscRunAsCredential = $Credential;

    } #end Script

} # end configuration
