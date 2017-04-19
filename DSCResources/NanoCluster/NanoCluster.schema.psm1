configuration NanoCluster {
<#
    .SYNOPSIS
        Creates a failover cluster
#>
    param (
        ## Name (FQDN) of the failover cluster to create.
        [Parameter(Mandatory)]
        [System.String] $ClusterName,

        ## Static IP address to assign to the cluster.
        [Parameter(Mandatory)]
        [System.String] $StaticAddress,

        ## One or more cluster nodes (FQDNs) to add to the cluster.
        [Parameter(Mandatory)]
        [System.String[]] $ClusterNode,

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

    Script "NanoCluster$($ClusterName.Replace('.',''))" {

        GetScript = {

            if (-not (Get-Module -Name FailoverClusters -ListAvailable))
            {
                throw ("Missing 'FailoverClusters' module.");
            }

            $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;

            return @{ Result = $cluster.Name; }

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

                $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;

                if ($null -eq $cluster)
                {
                    Write-Verbose -Message ("Cluster not found.");
                    return $false;
                }

                $isCompliant = $true;
                $clusterNodes = Get-ClusterNode -Cluster $cluster | Select -ExpandProperty Name;

                foreach ($node in $clusterNodes)
                {
                    if ($node -notin $using:ClusterNode)
                    {
                        Write-Verbose -Message ("Unexpected cluster node '{0}'." -f $node);
                        $isCompliant = $false;
                    }
                }

                foreach ($node in $using:ClusterNode)
                {
                    if ($node -notin $ClusterNodes)
                    {
                        Write-Verbose -Message ("Missing cluster node '{0}'." -f $node);
                        $isCompliant = $false;
                    }

                }

                return $isCompliant;

            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction Stop;
            }

        } #end TestScript

        SetScript = {

            try
            {
                $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;

                if ($null -eq $cluster)
                {
                    Write-Verbose ("Creating cluster '{0}'." -f $using:ClusterName);
                    $cluster = New-Cluster -Name $using:ClusterName -StaticAddress $using:StaticAddress -Node $using:ClusterNode -NoStorage;
                }

                $clusterNodes = Get-ClusterNode -Cluster $cluster | Select -ExpandProperty Name;

                foreach ($node in $using:ClusterNode)
                {
                    if ($node -notin $ClusterNodes)
                    {
                        Write-Verbose ("Adding cluster node '{0}'." -f $node);
                        Add-ClusterNode -Cluster $cluster -Name $node -NoStorage;
                    }
                }

                foreach ($node in $clusterNodes)
                {
                    if ($node -notin $using:ClusterNode)
                    {
                        Write-Verbose ("Evicting cluster node '{0}'." -f $node);
                        Remove-ClusterNode -Cluster $cluster -Name $node -Force;
                    }
                }
            }
            catch
            {
                Write-Error -ErrorRecord $_ -ErrorAction Stop;
            }

        } #SetScript

        PsDscRunAsCredential = $Credential;

    } #Script NanoCluster

} # end configuration
