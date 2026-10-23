# Test API EasyHealth
$headers = @{
    "Content-Type" = "application/json"
}

$body = @{
    userId = "test123"
    fullName = "Test Patient"
    email = "test@easyhealth.com"
    phone = "1234567890"
    role = "patient"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "http://localhost:4001/api/auth/register" -Method POST -Headers $headers -Body $body
    Write-Host "✅ Registration successful!"
    Write-Host "Response: $($response | ConvertTo-Json -Depth 3)"
} catch {
    Write-Host "❌ Registration failed: $($_.Exception.Message)"
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
    Write-Host "Content: $($_.Exception.Response.Content | ConvertFrom-Json)"
}
