param(
    [Parameter(Mandatory = $true)]
    [string]$BaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$SenderAccessToken,

    [Parameter(Mandatory = $true)]
    [int]$ReceiverUserId,

    [Parameter(Mandatory = $false)]
    [string]$DepositAccessToken,

    [Parameter(Mandatory = $false)]
    [int]$GiftWorkers = 50,

    [Parameter(Mandatory = $false)]
    [int]$DepositWorkers = 50,

    [Parameter(Mandatory = $false)]
    [decimal]$GiftAmount = 1,

    [Parameter(Mandatory = $false)]
    [decimal]$DepositAmount = 1
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($DepositAccessToken)) {
    $DepositAccessToken = $SenderAccessToken
}

function Invoke-WalletPost {
    param(
        [string]$Url,
        [string]$AccessToken,
        [hashtable]$Body
    )

    $headers = @{
        Authorization = "Bearer $AccessToken"
    }

    Invoke-RestMethod `
        -Method Post `
        -Uri $Url `
        -Headers $headers `
        -ContentType "application/json" `
        -Body ($Body | ConvertTo-Json -Depth 5)
}

function Start-WalletJob {
    param(
        [scriptblock]$ScriptBlock,
        [object[]]$Arguments
    )

    Start-Job -ScriptBlock $ScriptBlock -ArgumentList $Arguments
}

$runId = [Guid]::NewGuid().ToString("N")
$giftUrl = "$BaseUrl/api/wallet/gift"
$depositUrl = "$BaseUrl/api/wallet/deposit"

$giftScript = {
    param($Url, $Token, $ReceiverUserId, $Amount, $RunId, $Index)

    $body = @{
        receiverUserId = $ReceiverUserId
        amount = $Amount
        giftType = "stress-test"
        roomId = $null
        idempotencyKey = "gift-$RunId-$Index"
    }

    try {
        Invoke-RestMethod -Method Post -Uri $Url -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 5)
    }
    catch {
        [pscustomobject]@{
            failed = $true
            statusCode = $_.Exception.Response.StatusCode.value__
            message = $_.Exception.Message
        }
    }
}

$depositScript = {
    param($Url, $Token, $Amount, $RunId, $Index)

    $body = @{
        amount = $Amount
        idempotencyKey = "deposit-$RunId-$Index"
        description = "stress-test"
    }

    try {
        Invoke-RestMethod -Method Post -Uri $Url -Headers @{ Authorization = "Bearer $Token" } -ContentType "application/json" -Body ($body | ConvertTo-Json -Depth 5)
    }
    catch {
        [pscustomobject]@{
            failed = $true
            statusCode = $_.Exception.Response.StatusCode.value__
            message = $_.Exception.Message
        }
    }
}

Write-Host "Starting deposit concurrency test: $DepositWorkers workers"
$depositJobs = 1..$DepositWorkers | ForEach-Object {
    Start-WalletJob -ScriptBlock $depositScript -Arguments @($depositUrl, $DepositAccessToken, $DepositAmount, $runId, $_)
}

$depositResults = $depositJobs | Receive-Job -Wait -AutoRemoveJob
$depositFailures = @($depositResults | Where-Object { $_.failed -eq $true })
Write-Host "Deposit completed. Success=$($depositResults.Count - $depositFailures.Count), Failed=$($depositFailures.Count)"

Write-Host "Starting gift concurrency test: $GiftWorkers workers"
$giftJobs = 1..$GiftWorkers | ForEach-Object {
    Start-WalletJob -ScriptBlock $giftScript -Arguments @($giftUrl, $SenderAccessToken, $ReceiverUserId, $GiftAmount, $runId, $_)
}

$giftResults = $giftJobs | Receive-Job -Wait -AutoRemoveJob
$giftFailures = @($giftResults | Where-Object { $_.failed -eq $true })
Write-Host "Gift completed. Success=$($giftResults.Count - $giftFailures.Count), Failed=$($giftFailures.Count)"

[pscustomobject]@{
    runId = $runId
    depositWorkers = $DepositWorkers
    depositFailures = $depositFailures.Count
    giftWorkers = $GiftWorkers
    giftFailures = $giftFailures.Count
    duplicateTransactionIds = @($giftResults + $depositResults |
        Where-Object { $_.transactionId } |
        Group-Object transactionId |
        Where-Object { $_.Count -gt 1 } |
        Select-Object -ExpandProperty Name)
}
