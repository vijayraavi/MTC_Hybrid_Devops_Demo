Param(
[string]$CloudName,
[string]$ApplicationId,
[string]$ApplicationKey,
[string]$DirectoryTenant,
[string]$ResourceGroupName,
[string]$BuildFileLocation,
[string]$AppServicePlanSkuName,
[string]$AppServicePlanName,
[string]$Region,
[string]$Applicationname,
[string]$DatabaseServerName)
	
	
$ResourceManagerEndpoint = "https://management.local.azurestack.external" 
    $stackdomain = "local.azurestack.external"
    $name = "AzureStack-Tenant"         
 
    Write-Verbose "Retrieving endpoints from the $ResourceManagerEndpoint..." -Verbose

    $endpoints = Invoke-RestMethod -Method Get -Uri "$($ResourceManagerEndpoint.ToString().TrimEnd('/'))/metadata/endpoints?api-version=2015-01-01" -ErrorAction Stop
    $AzureKeyVaultDnsSuffix="vault.$($stackdomain)".ToLowerInvariant()
    $AzureKeyVaultServiceEndpointResourceId= $("https://vault.$stackdomain".ToLowerInvariant())
    $StorageEndpointSuffix = ($stackdomain).ToLowerInvariant()
    $aadAuthorityEndpoint = $endpoints.authentication.loginEndpoint
    $azureEnvironmentParams = @{
            Name                                     = $name
            ActiveDirectoryEndpoint                  = $endpoints.authentication.loginEndpoint.TrimEnd('/') + "/"
            ActiveDirectoryServiceEndpointResourceId = $endpoints.authentication.audiences[0]
            ResourceManagerEndpoint                  = $ResourceManagerEndpoint
            GalleryEndpoint                          = $endpoints.galleryEndpoint
            GraphEndpoint                            = $endpoints.graphEndpoint
            GraphAudience                            = $endpoints.graphEndpoint
            StorageEndpointSuffix                    = $StorageEndpointSuffix
            AzureKeyVaultDnsSuffix                   = $AzureKeyVaultDnsSuffix
            AzureKeyVaultServiceEndpointResourceId   = $AzureKeyVaultServiceEndpointResourceId
            EnableAdfsAuthentication                 = $aadAuthorityEndpoint.TrimEnd("/").EndsWith("/adfs", [System.StringComparison]::OrdinalIgnoreCase)
        } 
    Add-AzureRmEnvironment @azureEnvironmentParams

#catch {}

Write-Verbose "RG $ResourceGroupName" -Verbose
Write-Verbose "Loc $Region" -Verbose




$credentials = New-Object System.Management.Automation.PSCredential ($ApplicationId, $(ConvertTo-SecureString $ApplicationKey -AsPlainText -Force))

Login-AzureRmAccount -EnvironmentName $CloudName -ServicePrincipal -Credential $credentials -TenantId $DirectoryTenant
get-azurermsubscription
get-azurermresourcegroup -ResourceGroupName $ResourceGroupName -ev notPresent -ea 0

if ($notPresent)
{
    write-Verbose "Creating Resource Group $ResourceGroupName" -verbose
    new-azurermresourcegroup -Name $ResourceGroupName -Location $Region

}
Else
{
write-Verbose "Resource Group $ResourceGroupName already exists" -Verbose
}

$TemplateParameterObject = @{
  'AppServicePlanName' = $AppServicePlanName;
  'AppServicePlanSkuName' = $AppServicePlanSkuName;
  '_artifactslocation' = $BuildFileLocation;
  'WebAppName' =$Applicationname;
'databaseservername' =$databaseservername
};

new-azurermresourcegroupdeployment -name $Applicationname -ResourceGroupName $ResourceGroupName -templatefile ".\HybridDevops_Appservices-ASP.NET (PREVIEW)-CI/drop/deploy.json" -TemplateParameterObject $TemplateParameterObject