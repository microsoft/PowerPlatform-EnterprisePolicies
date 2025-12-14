function Get-LogDate {
    return (Get-Date -AsUTC).ToString("dd/MM/yyyy:HH:mm:ss:K")
}