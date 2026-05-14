param(
  [string]$ProjectId = "nurse-singles-international",
  [Parameter(Mandatory = $true)]
  [string]$BillingAccountId,
  [string]$BudgetDisplayName = "Nurse Singles Firebase Monthly Budget",
  [decimal]$MonthlyBudgetUsd = 100
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
  throw "gcloud CLI is required. Install Google Cloud SDK, then run this script again."
}

$budgetJson = @{
  displayName = $BudgetDisplayName
  budgetFilter = @{
    projects = @("projects/$ProjectId")
    calendarPeriod = "MONTH"
  }
  amount = @{
    specifiedAmount = @{
      currencyCode = "USD"
      units = [string][int]$MonthlyBudgetUsd
    }
  }
  thresholdRules = @(
    @{thresholdPercent = 0.5; spendBasis = "CURRENT_SPEND"},
    @{thresholdPercent = 0.8; spendBasis = "CURRENT_SPEND"},
    @{thresholdPercent = 1.0; spendBasis = "CURRENT_SPEND"},
    @{thresholdPercent = 1.2; spendBasis = "FORECASTED_SPEND"}
  )
} | ConvertTo-Json -Depth 10

$tmp = New-TemporaryFile
try {
  Set-Content -LiteralPath $tmp -Value $budgetJson -Encoding UTF8
  gcloud billing budgets create `
    --billing-account=$BillingAccountId `
    --budget-from-file=$tmp
} finally {
  Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
}
