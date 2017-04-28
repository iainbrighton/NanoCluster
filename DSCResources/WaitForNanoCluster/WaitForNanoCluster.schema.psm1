configuration WaitForNanoCluster {
<#
    .SYNOPSIS
        Creates a failover cluster
#>
    param (
        ## Name (FQDN) of the failover cluster to create.
        [Parameter(Mandatory)]
        [System.String] $ClusterName,

        ## Retry interval in seconds
        [System.Int32] $RetryInterval = 15,
        
        ## Retry count
        [System.Int32] $RetryCount = 20,

        ## Credential used to create the cluster and communicate with the cluster nodes.
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.CredentialAttribute()]
        $Credential

        #[Parameter()]
        #[ValidateSet('Present','Absent')]
        #[System.String] $Ensure = 'Present'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration

    Script "WaitForNanoCluster$($ClusterName.Replace('.',''))" {

        GetScript = {

            if (-not (Get-Module -Name FailoverClusters -ListAvailable 4>$null))
            {
                throw ("Missing 'FailoverClusters' module.");
            }

            $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;

            return @{ Result = ($null -ne $cluster); }

        } #end GetScript

        TestScript = {

            try
            {
                if (-not (Get-Module -Name FailoverClusters -ListAvailable 4>$null))
                {
                    throw ("Missing 'FailoverClusters' module.");
                }
                elseif (-not ($using:ClusterName).Contains('.'))
                {
                    Write-Warning -Message ("Cluster name should be specified as a FQDN");
                }
                
                $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;

                if ($null -eq $cluster)
                {
                    Write-Verbose -Message ("Cluster '{0}' was not found." -f $using:ClusterName);
                    return $false;
                }
                else
                {
                    Write-Verbose -Message ("Cluster '{0}' was found." -f $using:ClusterName);
                    return $true;
                }

            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction Stop;
            }

        } #end TestScript

        SetScript = {

            $isClusterFound = $false;
            Write-Verbose -Message ("Checking for cluster '{0}'..." -f $using:ClusterName);
            for ($count = 0; $count -lt $using:RetryCount; $count++)
            {
                try
                {
                    $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;
                    if ($null -ne $cluster)
                    {
                        $isClusterFound = $true;
                        Write-Verbose -Message ("Cluster '{0}' was found." -f $using:ClusterName);
                        break;
                    }
                }
                catch
                {
                    Write-Error -ErrorRecord $_ -ErrorAction Stop;
                }

                Write-Verbose -Message ("Cluster '{0}' was not found. Will retry again in {1} seconds." -f $using:ClusterName, $using:RetryInterval);
                Clear-DnsClientCache;
                Start-Sleep -Seconds $using:RetryInterval;

            } #end for

            if (-not $isClusterFound)
            {
                throw ("Cluster '{0}' not found after {1} attempts." -f $using:ClusterName, $count);
            }

        } #SetScript

        PsDscRunAsCredential = $Credential;

    } #Script NanoCluster

} # end configuration
