<#
Date: 11/29/2017
Author: Wesley Haakman 

.Synopsis
Report all Azure Resource Manager VMs withina a subscription

.Description
This script will report all Azure Resource Manager Virtual machines
Within a subscription and output the file to a table including the following information:
- Virtual Machine Name;
- Virtual Machine Location;
- Power State;
- Private IP Address;
- Public IP Address;
- Virtual Network;
- Subnet;
- Virtual Machine Size.


Usage: Login-AzureRMAccount before executing the script
       Define the output path variable

#>

# CHANGE THIS
$outputPath = "c:\temp\vms.html"

# Get VMs
$vms = Get-AzureRmVM

$vmarray =@()

foreach ($vm in $vms) 
    {     
      
        # Retrieve VM Status
        $vmstatus = Get-AzurermVM -Name $vm.Name -ResourceGroupName $vm.ResourceGroupName -Status  
      
        # Match private IP to VM
        $networkInterfaceID = $vm.NetworkProfile.NetworkInterfaces.id
        $networkInterfaces = Get-AzureRmNetworkInterface
        $vmNetworkInterface = $networkInterfaces |where {$_.Id -eq $networkInterfaceID}
        $vmPrivateIP = $vmNetworkInterface.IpConfigurations.PrivateIpAddress

        # Match public IP to VM
        $publicips = Get-AzureRmPublicIpAddress
        $publicIpId = ($networkInterfaces |where {$_.Id -eq $networkInterfaceID}).IpConfigurations.PublicIpAddress.id
        $pip = ($publicips |where {$_.id -eq $publicIpId}).IpAddress

        $VNetworkSubnetID=$vmNetworkInterface.IpConfigurations.subnet.id
        # Get Virtual network and Subnet name from net subnet ID string
        $vmVNet = $VNetworkSubnetID.split("/")[8]
        $vmSubnet = $VNetworkSubnetID.split("/")[10]
        
           
        $vmarray += New-Object PSObject -Property @{
             
            Name=$vm.Name 
            ResourceGroup=$vm.resourceGroupName
            PowerState=(get-culture).TextInfo.ToTitleCase(($vmstatus.statuses)[1].code.split("/")[1]) 
            Location=$vm.Location 
            PrivateIP=$vmPrivateIP
            PublicIP=$pip 
            VNet=$vmVNet
            Subnet=$vmSubnet
            Size=$vm.HardwareProfile.VmSize
       } 
    }
 
$beginning = { 
#HTML format for the table
 @'
    <html>
    <head>
    <title>Azure Resource Manager VM Report</title>
    <STYLE type="text/css">
        BODY{background-color:#b9d3ee;}
        TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;} 
        TH{font-family:SegoeUI, sans-serif; font-size:15; border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:#778899}
        TD{font-family:Consolas, sans-serif; font-size:12; border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
        tr:nth-child(odd) { background-color:#d3d3d3;} 
        tr:nth-child(even) { background-color:white;} 

    </STYLE>

    </head>
    <h1>Azure Resource Manager VM Report</h1>
    <table>
    <tr><th>VM Name</th><th>VM Resource Group</th><th>VM Location</th><th>Power State</th><th>Private IP Address</th><th>Public IP Address</th><th>Virtual Network</th><th>Subnet</th><th>Size</th></tr>
'@
}
#Mapping between Property and table
    $process = {
     


        '<tr>'
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.Name
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.ResourceGroup
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.Location
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.PowerState
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.PrivateIP
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.PublicIP
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.VNet
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.Subnet
        '<td bgcolor="#FFFFFF">{0}</td>' -f $_.Size
        '</tr>'

    }


    $end = { 
 @'
        </table>
        </html>
        </body>
'@


    }


$vmarray | ForEach-Object -Begin $beginning -Process $process -End $end |  Out-File -FilePath $outputPath -Encoding utf8
