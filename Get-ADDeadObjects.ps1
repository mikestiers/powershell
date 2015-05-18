$baseOU = "OU=USERS,DC=CORP,DC=LOCAL"
$terminationOU = "OU=DISABLED ACCOUNTS,DC=CORP,DC=LOCAL"
$exceptionsFile = "c:\temp\exceptions.txt"
$userExpiryThreshold = "120"
$modifyThreshold = "120"
$computerExpiryThreshold = "180"
$minimumGroupMembers = "2"
$currentdate = Get-Date

# Check distribution lists for members in $terminationOU
function termedUsersInGroups {
# checking all groups for members instead of checking termination OU for membership
# yes this is a slow and verbose way of doing it, but not you may not have access to 
# all groups outside of an OU
    "Termed users that are members of security groups"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    $groups = Get-ADGroup -Filter * -SearchBase $baseOU
    
        foreach ($group in $groups.Name)
        {
            try
            {
                $members = Get-ADGroupMember $group
                foreach ($member in $members)
                {
                    if ($member.distinguishedName.ToLower().Contains($terminationOU.ToLower()))
                    {
                        $member.Name + " - " + $group
                    }
                }
            }
            catch
            {
                "Error Processing: " + $group
            }
        }
    }

# Check user objects with passwords that have not been set past $userexpiryThreshold
function expiredUserPasswords {
    "Users that have expired passwords longer than " + $userExpiryThreshold + " days"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    $users = Get-ADUser -Filter * -SearchBase $baseOU -Properties passwordLastSet
    foreach ($user in $users)
    {
        try 
        {
            $dateDiff = New-TimeSpan -Start $user.passwordLastSet -End $currentDate
            if ($dateDiff.Days -ge $userExpiryThreshold  -and (checkException $user.samaccountname) -eq $Result)
            {
                $user.samaccountname + " - " + $dateDiff.Days + " days"
            }
        }
        catch
        {
            "Error Processing: " + $user.samaccountname
        }
    }
}

# Check for users that have not logged in for 120 days
function logonPastThreshold {
    $currentdate
}

# Check computers not modified in $computerExpiryThreshold
function expiredComputers {
    "Computer objects that have not been modified in " + $computerExpiryThreshold + " days"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    $computers = Get-ADComputer -Filter * -SearchBase $baseOU -Properties Modified
    foreach ($computer in $computers)
    {
        try 
        {
            $dateDiff = New-TimeSpan -Start $computer.Modified -End $currentDate
            if ($dateDiff.Days -ge $computerExpiryThreshold -and (checkException $computer.samAccountName) -eq $Result)
            {
                $computer.samAccountName + " - " + $dateDiff.Days + " days"
            }
        }
        catch
        {
            "Error Processing: " + $computer.samAccountName
        }
    }
}

# List all AD groups that have $minimumGroupMembers members
function emptyGroups {
    "Groups that have less than " + $minimumGroupMembers + " members"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    $groups = Get-ADGroup -Filter * -SearchBase $baseOU
    foreach ($group in $groups.Name)
    {
        try
        {
            $members = Get-ADGroupMember $group
            if ($members.Count -lt $minimumGroupMembers -and (checkException $group) -eq $Result)
            {
                $group + " has " + $members.Count + " members"
            }
        }
        catch
        {
            "Error Processing: " + $group
        }
    }
}

# Check user description field for exit date for data
function checkDescription {
    "User objects without a description field"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    $users = Get-ADUser -Filter * -SearchBase $baseOU -Properties description
    foreach ($user in $users)
    {
        $descriptionData = $user.description
        if (-not $descriptionData  -and (checkException $user.Name) -eq $Result)
        {
            $user.Name + " " + $user.description
        }
    }
}

# Check all groups without owners
function checkGroupOwners {
    "Groups that do not have an owner"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
    try
    {
        $groups = Get-ADGroup -Filter * -SearchBase $baseOU -Properties managedBy
        foreach ($group in $groups)
        {
            $owner = $group.managedBy
            if (-not $owner)
            {
                $group.name
            }
        }
    }
    catch
    {
        "Error Processing: " + $group.name
    }
}

# Check all groups groups with owners in $terminationOU
function checkOrphanedGroup {
    "Groups with owners in the terminated OU"
    "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    try
    {
        $groups = Get-ADGroup -Filter * -SearchBase $baseOU -Properties managedBy
        foreach ($group in $groups)
        {
            $owner = $group.managedBy
            if ($owner -match "Disabled" -and (checkException $group.name) -eq $Result)
            {
                $group.name + " has an owner in the disabled OU"
            }
        }
    }
    catch
    {
        "Error Processing: " + $group.name
    }
}

# Check items for exceptions
function checkException($exceptionItem) {
    foreach ($line in [System.IO.File]::Readlines($exceptionsFile))
    {
    if ($line -eq $exceptionItem)
           {
                "match"
                return $false
           }
    }
}

""
termedUsersInGroups
""
expiredUserPasswords
""
logonPastThreshold
""
expiredComputers
""
checkDescription
""
checkGroupOwners
""
checkOrphanedGroup
""
emptyGroups
