configuration NanoCluster {
<#
    .SYNOPSIS
        Creates a failover cluster
#>
    param (
        ## Name (FQDN) of the failover cluster to create.
        [Parameter(Mandatory = $true)]
        [System.String]
        $ClusterName,

        ## Static IP address to assign to the cluster.
        [Parameter(Mandatory = $true)]
        [System.String]
        $StaticAddress,

        ## One or more cluster nodes (FQDNs) to add to the cluster.
        [Parameter(Mandatory = $true)]
        [System.String[]]
        $ClusterNode,

        ## Credential used to create the cluster and communicate with the cluster nodes.
        [Parameter(Mandatory = $true)]
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

            if (-not (Get-Module -Name FailoverClusters -ListAvailable 4>$null))
            {
                throw ("Missing 'FailoverClusters' module.");
            }

            $cluster = Get-Cluster -Name $using:ClusterName -ErrorAction SilentlyContinue;

            return @{ Result = $cluster.Name; }

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
                    Write-Verbose -Message ("Cluster not found.");
                    return $false;
                }

                $isCompliant = $true;
                $clusterNodes = Get-ClusterNode -InputObject $cluster | Select-Object -ExpandProperty Name;
                ## Get-ClusterNode returns NetBIOS names so strip supplied nodes' domain names
                $clusterNetBIOSNodes = $using:ClusterNode | ForEach-Object { $_.Split('.')[0] };

                foreach ($node in $clusterNodes)
                {
                    if ($node -notin $clusterNetBIOSNodes)
                    {
                        Write-Verbose -Message ("Unexpected cluster node '{0}'." -f $node);
                        $isCompliant = $false;
                    }
                }

                foreach ($node in $clusterNetBIOSNode)
                {
                    if ($node -notin $ClusterNodes)
                    {
                        Write-Verbose -Message ("Missing cluster node '{0}'." -f $node);
                        $isCompliant = $false;
                    }
                }

                if ($isCompliant)
                {
                    Write-Verbose -Message ("Cluster '{0}' is in the desired state." -f $using:ClusterName);
                }
                else
                {
                    Write-Verbose -Message ("Cluster '{0}' is NOT in the desired state." -f $using:ClusterName);
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
                    ## Cluster cannot be created with a FQDN?!
                    $clusterNetBIOSName = ($using:ClusterName).Split('.')[0];
                    Write-Verbose ("Creating cluster '{0}'." -f $clusterNetBIOSName);
                    $cluster = New-Cluster -Name $clusterNetBIOSName -StaticAddress $using:StaticAddress -Node $using:ClusterNode -NoStorage;
                }

                $clusterNodes = Get-ClusterNode -InputObject $cluster | Select-Object -ExpandProperty Name;
                ## Get-ClusterNode returns NetBIOS names so strip supplied nodes' domain names
                $clusterNetBIOSNodes = $using:ClusterNode | ForEach-Object { $_.Split('.')[0] };

                foreach ($node in $clusterNodes)
                {
                    if ($node -notin $clusterNetBIOSNodes)
                    {
                        Write-Verbose ("Adding cluster node '{0}'." -f $node);
                        Add-ClusterNode -Cluster $cluster -Name $node -NoStorage;
                    }
                }

                foreach ($node in $clusterNetBIOSNode)
                {
                    if ($node -notin $ClusterNodes)
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
