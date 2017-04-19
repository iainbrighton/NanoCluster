# NanoClusters DSC Resources

The `NanoClusters` composite DSC resources provide a common set of DSC resources that simplify the deployment of a Nano
Server Hyper-Converged Cluster. As the native Windows PowerShell `FailoverClusters` cmdlets are not (yet) available on
Nano server, the xFailoverCluster DSC resources cannot be used as they do not support remote deployment and/or
configuration.

## Included Resources

__All resources must run on Windows Server 2016 Core (or GUI) with the Windows PowerShell `FailoverClusters` cmdlets installed.__

### NanoCluster

Creates a Windows failover cluster - remotely.

* **[String] ClusterName** (Required): Name (FQDN) of the failover cluster to create.
* **[String] StaticAddress** (Required): Static IP address to assign to the cluster.
* **[String[]] ClusterNode** (Required): One or more cluster nodes (FQDNs) to add to the cluster.
* **[PSCredential] Credential** (Required): Credential used to create the cluster and communicate with the cluster nodes.

### NanoClusterS2D

Creates a Storage Spaces Direct (S2D) cluster - remotely.

* **[String] ClusterName** (Required): Name of the failover cluster/node (FQDN) to enable S2D on.
* **[PSCredential] Credential** (Required): Credential used to create the clustered storage and communicate with the cluster nodes.
* **[Boolean] AutoConfig** (Write): Indicates that the pool should be automatically created and configured. If you do not want the pool to be automatically created, but created manually, you should set AutoConfig to false. Defaults to true.
* **[String] PoolFriendlyName** (Write): Specifies the friendly name of the S2D pool when it is created.
* **[String] CacheState** (Write): Specifies the S2D cache state. { Enabled | Disabled }. Defaults to Enabled.
* **[Boolean] SkipEligibilityChecks** (Write): Indicates that this cmdlet skips cache eligibility checks.

### NanoClusterS2DVolume

Creates a Storage Spaces Direct (S2D) storage volume - remotely.

* **[String] ClusterName** (Required): Name of the failover cluster/node (FQDN) to create the volume on.
* **[String] StoragePoolFriendlyName** (Required): Specifies an array of storage pool friendly names. The volume is created in the storage pools specified.
* **[String] FriendlyName** (Required): Specifies a friendly name assigned to the volume.
* **[PSCredential] Credential** (Required): Credential used to create the clustered storage and communicate with the cluster nodes.
* **[UInt64] Size** (Write): Specifies the size of the volume - __in bytes__ - to create.
* **[Boolean] UseMaximumSize** (Write): If specified, the file system to use for the volume. Defaults to CSVFS_ReFS. 
  * _This setting will override the -Size parameter if specified._
* **[String] FileSystem** (Write): Specifies the file system to use for the volume. { CSVFS\_NTFS | CSVFS\_ReFS }. Defaults to CSVFS\_ReFS.
* **[UInt16] PhysicalDiskRedundancy** (Write): Specifies the physical disk redundancy value to use during the creation of the volume. Defaults to 2.
* **[String] ProvisioningType** (Write): Specifies the type of provisioning. Specify Fixed for storage spaces that use storage tiers or a clustered storage pool. { Fixed }. Defaults to Fixed.
* **[String] ResiliencySettingName** (Write): By default, when you specify Mirror, Storage Spaces creates a two-way mirror, and when you specify Parity, Storage Spaces creates a single-parity space. { Mirror | Parity }. Defaults to Mirror.
* **[String] MediaType** (Write): Specifies the media type of the storage tier. Use SCM for storage-class memory such as NVDIMMs { HDD | SSD | CSM }. Defaults to HDD.
