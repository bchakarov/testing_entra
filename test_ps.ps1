#region Params
$clientId = "fbfe3e4f-5c80-48e5-8364-01445ab2793a"
$clientSecret = "secret"
$tenantId = "6061c477-28c6-488f-91c3-ff587946cc72"
$userId = "5a51cb9d-26eb-427e-9079-5774a3e8ba25"
$schemaExtId = "exti51xp4di_licenseInfo"
$groupId = ""
#endregion

#region Get Token
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
# $body = @{
#     id          = "licenseInfo"                        # Graph will prefix this, e.g. extk9eruy7c_licenseInfo
#     description = "License assignment info for users"
#     targetTypes = @("User")
#     owner       = $clientId                            # appId of the owning app registration
#     properties  = @(
#         @{
#             name = "licenseIds"
#             type = "String"
#         }
#     )
# } | ConvertTo-Json -Depth 5

# $schemaExt = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/schemaExtensions" `
#     -Method Post `
#     -Headers $headers `
#     -ContentType "application/json" `
#     -Body $body

# $schemaExtId = $schemaExt.id   # e.g. extk9eruy7c_licenseInfo
# Write-Host "Schema extension created: $schemaExtId" -ForegroundColor Green
# $schemaExt | ConvertTo-Json -Depth 5
#endregion

#region Assign schema extension value to a user
# $body = @{
#     $schemaExtId = @{
#         licenseIds = "LIC-001;LIC-002;LIC-003"
#     }
# } | ConvertTo-Json -Depth 5

# Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/${userId}" `
#     -Method Patch `
#     -Headers $headers `
#     -ContentType "application/json" `
#     -Body $body

# Write-Host "Schema extension value set on user $userId" -ForegroundColor Green
#endregion

#region Query user with schema extension
Write-Host "Retrieving user by id."
$uri = "https://graph.microsoft.com/v1.0/users/${userId}?`$select=id,displayName,${schemaExtId}"

$response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
$response | ConvertTo-Json -Depth 5
#endregion

#region Filter users by schema extension value (eq operator)
Write-Host "Retrieving users by schema extension eq operator."
$uri = "https://graph.microsoft.com/v1.0/users?`$filter=${schemaExtId}/licenseIds eq 'LIC-001;LIC-002;LIC-003'&`$select=id,displayName,${schemaExtId}"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    $response | ConvertTo-Json -Depth 5
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
    $errorBody = $reader.ReadToEnd()
    $reader.Close()

    Write-Host "Error $statusCode" -ForegroundColor Red
    Write-Host $errorBody
}
#endregion

#region Filter users by schema extension value (contains operator)
Write-Host "Retrieving users by schema extension contains operator."
$uri = "https://graph.microsoft.com/v1.0/users?`$filter=${schemaExtId}/licenseIds contains 'LIC-001'&`$select=id,displayName,${schemaExtId}"

try {
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
    $response | ConvertTo-Json -Depth 5
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorBody = $_.ErrorDetails.Message

    Write-Host "Error $statusCode" -ForegroundColor Red
    Write-Host $errorBody
}
#endregion

#region Add user to security group
Write-Host "Adding user to security group."
$body = @{
    "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/${userId}"
} | ConvertTo-Json
 
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/${groupId}/members/`$ref" `
        -Method Post `
        -Headers $headers `
        -ContentType "application/json" `
        -Body $body
 
    Write-Host "User $userId added to group $groupId" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorBody = $_.ErrorDetails.Message
 
    Write-Host "Error $statusCode" -ForegroundColor Red
    Write-Host $errorBody
}
#endregion

#region Remove user from security group
Write-Host "Removing user from security group."
try {
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/${groupId}/members/${userId}/`$ref" `
        -Method Delete `
        -Headers $headers
 
    Write-Host "User $userId removed from group $groupId" -ForegroundColor Green
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorBody = $_.ErrorDetails.Message
 
    Write-Host "Error $statusCode" -ForegroundColor Red
    Write-Host $errorBody
}
#endregion

#region Check if user is member of security group
Write-Host "Checking if user is member of security group."
try {
    $uri = "https://graph.microsoft.com/v1.0/groups/${groupId}/members?`$filter=id eq '${userId}'"
    $response = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
 
    if ($response.value.Count -gt 0) {
        Write-Host "User $userId IS a member of group $groupId" -ForegroundColor Green
    }
    else {
        Write-Host "User $userId is NOT a member of group $groupId" -ForegroundColor Yellow
    }
}
catch {
    $statusCode = $_.Exception.Response.StatusCode.value__
    $errorBody = $_.ErrorDetails.Message
 
    Write-Host "Error $statusCode" -ForegroundColor Red
    Write-Host $errorBody
}
#endregion
