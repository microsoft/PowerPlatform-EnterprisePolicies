class HttpClientResultHeaderMock
{
    [hashtable]$Headers
    HttpClientResultHeaderMock($ContentType)
    {
        $this.Headers = @{
            "Content-Type" = $ContentType
        }
    }
    [string]GetValues($Header)
    {
        return $this.Headers[$Header]
    }
}

class HttpClientResultContentMock
{
    [string]$ReadAsyncValue
    [HttpClientResultHeaderMock]$Headers
    HttpClientResultContentMock($ReadAsyncValue, $ContentType)
    {
        $this.ReadAsyncValue = $ReadAsyncValue
        $this.Headers = [HttpClientResultHeaderMock]::new($ContentType)
    }

    [string]ReadAsStringAsync()
    {
        return $this.ReadAsyncValue
    }
}

class HttpClientResultMock
{
    [string]$ReadContent
    [string]$ContentType
    
    HttpClientResultMock($ReadContent)
    {
        $this.ReadContent = $ReadContent
        $this.ContentType = ""
    }
    HttpClientResultMock($ReadContent, $ContentType)
    {
        $this.ReadContent = $ReadContent
        $this.ContentType = $ContentType
    }

    [System.Net.HttpStatusCode]$StatusCode = [System.Net.HttpStatusCode]::OK
    [string]$ReasonPhrase = "mock http error message"
    [HttpClientResultContentMock]$Content = [HttpClientResultContentMock]::new($ReadContent, $ContentType)
}

class HttpClientMock
{
    [string]SendAsync($request)
    {
        return "SendAsyncResult"
    }
}


$ExportableTypes =@(
    [HttpClientResultHeaderMock]
    [HttpClientResultContentMock]
    [HttpClientResultMock]
    [HttpClientMock]
)

# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [psobject].Assembly.GetType(
    'System.Management.Automation.TypeAccelerators'
)
# Ensure none of the types would clobber an existing type accelerator.
# If a type accelerator with the same name exists, throw an exception.
$ExistingTypeAccelerators = $TypeAcceleratorsClass::Get
foreach ($Type in $ExportableTypes) {
    if($Type.FullName -in $global:ImportedTypes) {
        continue
    }
    if ($Type.FullName -in $ExistingTypeAccelerators.Keys) {
        $Message = @(
            "Unable to register type accelerator '$($Type.FullName)'"
            'Accelerator already exists.'
        ) -join ' - '

        throw [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new($Message),
            'TypeAcceleratorAlreadyExists',
            [System.Management.Automation.ErrorCategory]::InvalidOperation,
            $Type.FullName
        )
    }
}
# Add type accelerators for every exportable type.
foreach ($Type in $ExportableTypes) {
    $TypeAcceleratorsClass::Add($Type.FullName, $Type)
    [string[]]$global:ImportedTypes += $Type.FullName
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach($Type in $ExportableTypes) {
        $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()