# Launch SLES-HAE of SLES4SAP cluster nodes

# Enable all some pre deployment steps (disabled by default)
pre_deployment = true

# Region where to deploy the configuration
aws_region = "%REGION%"

# Use an already existing vpc. Make sure the vpc has the internet gateway already attached
#vpc_id = "vpc-xxxxxxxxxxxxxxxxx"

# Use an already existing security group
#security_group_id = "sg-xxxxxxxxxxxxxxxxx"

# vpc address range in CIDR notation
# Only used if the vpc is created by terraform or the user doesn't have read permissions in this
# resource. To use the current vpc address range set the value to an empty string
# To define custom ranges
vpc_address_range = "10.0.0.0/16"
# Or to use already existing vpc address ranges
#vpc_address_range = ""

# Instance type to use for the hana cluster nodes
hana_instancetype = "%MACHINE_TYPE%"

# Disk type for HANA
hana_data_disk_type = "gp2"

# Number of nodes in the cluster
hana_count = "2"

# SSH Public key location to configure access to the remote instances
public_key_location = "~/.ssh/id_rsa.pub"

# Private SSH Key location
private_key_location = "~/.ssh/id_rsa"

# Custom AMI for nodes
#hana_os_image = "ami-xxxxxxxxxxxxxxxxx"
# Or use a pattern to find the image
#hana_os_image = "suse-sles-sap-15-sp1-byos"
hana_os_image = "%SLE_IMAGE%"

# Custom owner for private AMI
hana_os_owner = "self"

# aws-cli credentials data
# access keys parameters have preference over the credentials file (they are self exclusive)
#aws_access_key_id = my-access-key-id
#aws_secret_access_key = my-secret-access-key
# aws-cli credentials file. Located on ~/.aws/credentials on Linux, MacOS or Unix or at C:\Users\USERNAME\.aws\credentials on Windows
aws_credentials = "/root/amazon_credentials"

# Hostname, without the domain part
name = "hana"

# Enable system replication and HA cluster
hana_ha_enabled = true

# S3 bucket where HANA installation master is located
#hana_inst_master = "s3://path/to/your/hana/installation/master/51053381"
# Or you can combine the `hana_inst_master` with `hana_platform_folder` variable.
#hana_inst_master = "s3://path/to/your/hana/installation/master"
# Specify the path to already extracted HANA platform installation media, relative to hana_inst_master mounting point.
# This will have preference over hana archive installation media
#hana_platform_folder = "51053381"
hana_inst_master = "%HANA_BUCKET%"

# Or specify the path to the HANA installation archive file in either of SAR, RAR, ZIP, EXE formats, relative to the 'hana_inst_media' mounting point
# For multipart RAR archives, you only need to provide the first part EXE file name.
# If using hana sar archive, please also provide the compatible version of sapcar executable to extract the sar archive
# HANA installation archives be extracted to path specified at hana_extract_dir (optional, by default /sapmedia/HANA)
#hana_archive_file = "IMDB_SERVER.SAR"
#hana_sapcar_exe = "SAPCAR"
#hana_extract_dir = "/sapmedia/HDBSERVER"

# Device used by node where HANA will be installed
#hana_disk_device = "/dev/xvdd"

# IP address used to configure the hana cluster floating IP. It must be in other subnet than the machines!
hana_cluster_vip = "192.168.1.10"

# Enable SBD for the hana cluster
#hana_cluster_sbd_enabled = true

# Enable Active/Active HANA setup (read-only access in the secondary instance)
#hana_active_active = true

# SBD related variables
# In order to enable SBD, an ISCSI server is needed as right now is the unique option
# All the clusters will use the same mechanism
# In order to enable the iscsi machine creation sbd_enabled must be set to true for any of the clusters

# iSCSI OS image
#iscsi_os_image = "ami-xxxxxxxxxxxxxxxxx"
#iscsi_os_owner = "self"

# iSCSI server address. It should be in same iprange as hana_ips
#iscsi_srv_ip = "10.0.0.254"
# Number of LUN (logical units) to serve with the iscsi server. Each LUN can be used as a unique sbd disk
#iscsi_lun_count = 3
# Disk size in GB used to create the LUNs and partitions to be served by the ISCSI service
#iscsi_disk_size = 10

# Path to a custom ssh public key to upload to the nodes
# Used for cluster communication for example
cluster_ssh_pub = "salt://sshkeys/cluster.id_rsa.pub"

# Path to a custom ssh private key to upload to the nodes
# Used for cluster communication for example
cluster_ssh_key = "salt://sshkeys/cluster.id_rsa"

# Each host IP address (sequential order). The first ip must be in 10.0.0.0/24 subnet and the second in 10.0.1.0/24 subnet
hana_ips = ["10.0.1.5", "10.0.2.5"]

# Repository url used to install HA/SAP deployment packages"
# The latest RPM packages can be found at:
# https://download.opensuse.org/repositories/network:/ha-clustering:/Factory/{YOUR OS VERSION}
# Contains the salt formulas rpm packages.
# To auto detect the SLE version
#ha_sap_deployment_repo = "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/"
# Specific SLE version used in all the created machines
#ha_sap_deployment_repo = "http://download.opensuse.org/repositories/network:/ha-clustering:/Factory/SLE_15/"
ha_sap_deployment_repo = "%HA_SAP_REPO%"

# Optional SUSE Customer Center Registration parameters
#reg_code = "<<REG_CODE>>"
#reg_email = "<<your email>>"
reg_code = "%SCC_REGCODE_SLES4SAP%"

# For any sle12 version the additional module sle-module-adv-systems-management/12/x86_64 is mandatory if reg_code is provided
#reg_additional_modules = {
#    "sle-module-adv-systems-management/12/x86_64" = ""
#    "sle-module-containers/12/x86_64" = ""
#    "sle-ha-geo/12.4/x86_64" = "<<REG_CODE>>"
#}

# Cost optimized scenario
#scenario_type: "cost-optimized"

# To disable the provisioning process
#provisioner = ""

# Run provisioner execution in background
#background = true

# Monitoring variables

# Enable the host to be monitored by exporters
#monitoring_enabled = true

#monitoring_os_image = "ami-xxxxxxxxxxxxxxxxx"
#monitoring_os_owner = "self"

# IP address of the machine where Prometheus and Grafana are running. Must be in 10.0.0.0/24 subnet
#monitoring_srv_ip = "10.0.0.253"

# QA variables

# Define if the deployment is using for testing purpose
# Disable all extra packages that do not come from the image
# Except salt-minion (for the moment) and salt formulas
# true or false (default)
#qa_mode = false

# Execute HANA Hardware Configuration Check Tool to bench filesystems
# qa_mode must be set to true for executing hwcct
# true or false (default)
#hwcct = false

# drbd related variables

# netweaver will use AWS efs for nfs share by default, unless drbd is enabled
# Enable drbd cluster
drbd_enabled = true
#drbd_instancetype = "t2.micro"
drbd_os_image = "%SLE_IMAGE%"
drbd_os_owner = "self"
#drbd_data_disk_size = 15
#drbd_data_disk_type = gp2

# Each drbd cluster host IP address (sequential order).
drbd_ips = ["10.0.5.20", "10.0.6.21"]
drbd_cluster_vip = "192.168.1.20"

# Netweaver variables

#netweaver_enabled = true
#netweaver_instancetype = "r3.8xlarge"
#netweaver_os_image = "ami-xxxxxxxxxxxxxxxxx"
#netweaver_os_owner = "self"
#AWS efs performance mode used by netweaver nfs share, if efs storage is used
#netweaver_efs_performance_mode = "generalPurpose"
#netweaver_ips = ["10.0.2.7", "10.0.3.8", "10.0.2.9", "10.0.3.10"]
#netweaver_virtual_ips = ["192.168.1.20", "192.168.1.21", "192.168.1.22", "192.168.1.23"]


# Enabling this option will create a ASCS/ERS HA available cluster together with a PAS and AAS application servers
# Set to false to only create a ASCS and PAS instances
#netweaver_ha_enabled = true

# Set the Netweaver product id for HA (this is just an example)
#netweaver_product_id = NW750.HDB.ABAPHA
# Fon non HA
#netweaver_product_id = NW750.HDB.ABAP

# Enable SBD for the netweaver cluster
#netweaver_cluster_sbd_enabled = true

# Netweaver installation required folders
# This S3 bucket must contain the next software (select the version you want to install of course)
#SWPM - `IND:SLTOOLSET:2.0:SWPM:*:LINUX_X86_64:*x`
#Netweaver export - `SAP:NETWEAVER:750:DVD_EXPORT:SAP NetWeaver 750 Installation Export DVD 1/1:D51050829_2`
#HANA Platform- `HDB:HANA:2.0:LINUX_X86_64:SAP HANA PLATFORM EDITION 2.0::BD51053787`
#Sapexe folder files:
#igsexe_23-20007790.sar  igshelper_4-10010245.sar  SAPEXE_501-80002573.SAR  SAPEXEDB_501-80002572.SAR  SAPHOSTAGENT45_45-20009394.SAR

#netweaver_s3_bucket = "s3://path/to/your/netweaver/installation/s3bucket"
# SAP SWPM installation folder, relative to the netweaver_s3_bucket folder
#netweaver_swpm_folder     =  "your_swpm"
# Or specify the path to the sapcar executable & SWPM installer sar archive, relative to the netweaver_s3_bucket folder
# The sar archive will be extracted to path specified at netweaver_extract_dir under SWPM directory (optional, by default /sapmedia/NW/SWPM)
#netweaver_sapcar_exe = "your_sapcar_exe_file_path"
#netweaver_swpm_sar = "your_swpm_sar_file_path"
# Folder where needed SAR executables (sapexe, sapdbexe) are stored, relative to the netweaver_s3_bucket folder
#netweaver_sapexe_folder   =  "kernel_nw75_sar"
# Additional media archives or folders (added in start_dir.cd), relative to the netweaver_s3_bucket folder
#netweaver_additional_dvds = ["dvd1", "dvd2"]
