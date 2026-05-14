param(
  [string]$Bucket = 'gs://nurse-singles-international.firebasestorage.app'
)

$ErrorActionPreference = 'Stop'

if (!(Get-Command gcloud -ErrorAction SilentlyContinue)) {
  throw 'gcloud is required to apply Firebase Storage CORS settings.'
}

gcloud storage buckets update $Bucket --cors-file=storage.cors.json
