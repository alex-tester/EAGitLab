# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function Get-GitUserID
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$UserName,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{'PRIVATE-TOKEN' = $APIKey}

#Get total number of pages; pagnation will allow max 100 users per page. Default is 20 per page.
$IRWUsers = Invoke-WebRequest -Uri $BaseURL/users -Headers $header -Method Get
[int]$TotalPages = $IRWUsers.Headers.'X-Total-Pages'

$UserObj = @()
while ($TotalPages -gt 0)
{
$UserQuery = Invoke-WebRequest -Uri $BaseURL/users?page=$TotalPages -Headers $header -Method Get
$UserObj += $UserQuery.Content | ConvertFrom-Json
$TotalPages--
$UserQuery = ''
}
$TargetUser = $UserObj | Where-Object -Property username -eq $UserName
return $TargetUser.id
}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function Get-GitGroupID
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$GroupName,
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{'PRIVATE-TOKEN' = $APIKey}

$IRWGroups = Invoke-WebRequest -Uri $BaseURL/groups?all_available=true -Headers $header -Method Get

[int]$TotalPages = $IRWGroups.Headers.'X-Total-Pages'

$GroupObj = @()

while ($TotalPages -gt 0)
{
    $GroupQuery = Invoke-WebRequest -Uri $BaseURL/groups?all_available=true"&"page=$TotalPages -Headers $header -Method Get
    $GroupObj += $GroupQuery.Content | ConvertFrom-Json
    $TotalPages--
    $GroupQuery = ''
}

$TargetGroup = $GroupObj | where -Property full_name -ceq $GroupName
return $TargetGroup.id
}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function Get-AllGitUsers
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{'PRIVATE-TOKEN' = $APIKey}

$IRWUsers = Invoke-WebRequest -Uri $BaseURL/users -Headers $header -Method Get

[int]$TotalPages = $IRWUsers.Headers.'X-Total-Pages'

$UserObj = @()
while ($TotalPages -gt 0)
{
$UserQuery = Invoke-WebRequest -Uri $BaseURL/users?page=$TotalPages -Headers $header -Method Get
$UserObj += $UserQuery.Content | ConvertFrom-Json
$TotalPages--
$UserQuery = ''
}
return $UserObj
}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function Get-AllGitGroups
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{'PRIVATE-TOKEN' = $APIKey}

$IRWGroups = Invoke-WebRequest -Uri $BaseURL/groups?all_available=true -Headers $header -Method Get

[int]$TotalPages = $IRWGroups.Headers.'X-Total-Pages'

$GroupObj = @()

while ($TotalPages -gt 0)
{
    $GroupQuery = Invoke-WebRequest -Uri $BaseURL/groups?all_available=true"&"page=$TotalPages -Headers $header -Method Get
    $GroupObj += $GroupQuery.Content | ConvertFrom-Json
    $TotalPages--
    $GroupQuery = ''
}

return $GroupObj

}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function Get-AllGitGroupsAndMembers
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{'PRIVATE-TOKEN' = $APIKey}

#Get number of pages
$Groups = Invoke-WebRequest -Uri $BaseURL/groups?all_available=true -Headers $header -Method Get

[int]$GroupPages = $Groups.Headers.'X-Total-Pages'

#Gather list of groups
$GroupObj = @()

while ($GroupPages -gt 0)
{
    $GroupQuery = Invoke-WebRequest -Uri $BaseURL/groups?all_available=true"&"page=$GroupPages -Headers $header -Method Get
    $GroupObj += $GroupQuery.Content | ConvertFrom-Json
    $GroupPages--
    $GroupQuery = ''
}

#Get the members of each group
$GroupMemberResults = @()

foreach ($Group in $GroupObj)
{
    write-host "Getting members of" $Group.name -ForegroundColor Green
    $GroupID = $Group.ID
    
    $Members=Invoke-WebRequest -Uri $BaseURL/groups/$GroupID/members -Headers $header -Method Get
    
    [int]$MemberPages = $Members.Headers.'X-Total-Pages'
    
    $MemberObj = @()

    while ($MemberPages -gt 0)
    {
    $MemberQuery = Invoke-WebRequest -Uri $BaseURL/groups/$GroupID/members?page=$MemberPages -Headers $header -Method Get
    $MemberObj += $MemberQuery.Content | ConvertFrom-Json
    $MemberPages--
    $MemberQuery = ''
    }

    foreach ($Member in $MemberObj)
    {
    $GroupDetails = @{
        Group       = $Group.name
        GroupID     = $GroupID
        Username    = $Member.username
        UserID      = $Member.id
        AccessLevel = $Member.access_level
        }
    $GroupMemberResults+= New-Object -TypeName PSObject -Property $GroupDetails
    }

}

return $GroupMemberResults
}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function New-GitUser
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$Username,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)


$header = @{'PRIVATE-TOKEN' = $APIKey}

$UsrObj = Get-ADUser $Username -Properties EmailAddress | select Name, EmailAddress

$NewUserBody = @{
email             = $UsrObj.EmailAddress
password          = '12345678'
username          = $Username
name              = $UsrObj.Name
skip_confirmation = 'true'
}

Invoke-RestMethod -Uri $BaseURL/users -Headers $header -Method Post -Body $NewUserBody

}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function New-GitGroup
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$GroupName,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$GroupPath,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
$GroupDescription,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
[ValidateSet("private", "internal", "public")]
$GroupVisibility,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
[bool]$GroupLFSEnabled,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
[bool]$GroupRequestAccessEnabled = $true,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
$ParentGroupID,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
$SharedRunnersMinuteLimit,

[Parameter(Mandatory=$false)]
[ValidateNotNullOrEmpty()]
$SudoID,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

if ($SudoID)
{
    $Header = @{
    'PRIVATE-TOKEN' = $APIKey
    sudo = $SudoID
    }
}
else
{
    $Header = @{'PRIVATE-TOKEN' = $APIKey}
}


$NewGroupBody = @{
name                         = $GroupName
path                         = $GroupPath
description                  = $GroupDescription
visibility                   = $GroupVisibility
lfs_enabled                  = $GroupLFSEnabled
request_access_enabled       = $GroupRequestAccessEnabled
parent_id                    = $ParentGroupID
shared_runners_minutes_limit = $SharedRunnersMinuteLimit
}


Invoke-RestMethod -Uri $BaseURL/groups -Headers $Header -Method Post -Body $NewGroupBody
}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function New-GitGroupAccessRequest
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$UserID,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$GroupID,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{
'PRIVATE-TOKEN' = $APIKey
sudo = $UserID
}

Invoke-RestMethod -Uri $BaseURL/groups/$GroupID/access_requests -Headers $header -Method Post

}

# .ExternalHelp .\en-US\EAGitLab.psm1-Help.xml
function Add-GitGroupMember
{
param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$BaseURL,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$UserID,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[ValidateSet("10", "20", "30", "40", "50")]
$AccessLevel,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$GroupID,

[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
$APIKey
)

$Header = @{'PRIVATE-TOKEN' = $APIKey}

$AddMemberBody = @{
user_id = $UserID
access_level = $AccessLevel
}

Invoke-RestMethod -Uri $BaseURL/groups/$GroupID/members -Headers $header -Body $AddMemberBody -Method Post
}


