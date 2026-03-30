#region Params
$clientId = "client_id"
$clientSecret = "secret"
#endregion

#region Get Token
$tenantId = "tenant_id"

$tokenBody = @{
    client_id     = $clientId
    scope         = "https://graph.microsoft.com/.default"
    client_secret = $clientSecret
    grant_type    = "client_credentials"
}

$tokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/token" `
    -Method Post `
    -ContentType "application/x-www-form-urlencoded" `
    -Body $tokenBody

$accessToken = $tokenResponse.access_token

$headers = @{
    Authorization = "Bearer $accessToken"
}

Write-Host "Token acquired successfully." -ForegroundColor Green
#endregion

#region Create schema extension
# $appObjectId = "7b8e00a8-7705-4d0d-be0f-94d626c6bfc8" # object id not client id

# $body = @{
#     name          = "licenseIds"
#     dataType      = "String"
#     targetObjects = @("User")
# } | ConvertTo-Json

# $extension = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/applications/${appObjectId}/extensionProperties" `
#     -Method Post `
#     -Headers $headers `
#     -ContentType "application/json" `
#     -Body $body

# $extension | ConvertTo-Json -Depth 5
# # Note the full name returned, e.g. extension_<appIdNoHyphens>_licenseIds
#endregion

#region Set schema extension on user
# $userId = "5a51cb9d-26eb-427e-9079-5774a3e8ba25"
# $extensionName = $extension.name  # e.g. extension_8c5b6a2ce02b47cf9f754aa4883c6480_licenseIds

# $body = @{
#     $extensionName = "LIC-001,LIC-002,LIC-003"
# } | ConvertTo-Json

# Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/${userId}" `
#     -Method Patch `
#     -Headers $headers `
#     -ContentType "application/json" `
#     -Body $body

# Write-Host "Extension value set on user." -ForegroundColor Green
#endregion

#region Queries
$ext = "extension_fbfe3e4f5c8048e5836401445ab2793a_licenseIds"
$select = "id,displayName,$ext"

# Users where the extension is not null
$uri = "https://graph.microsoft.com/v1.0/users?`$filter=${ext} ne null&`$select=${select}"

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
$response.value | ConvertTo-Json -Depth 5
#endregion
