# Here's the story.
#
# We need to grant NT SERVICE\ncdns permission to manipulate
# HKLM\Software\[Wow6432Node\]Microsoft\EnterpriseCertificates\Root\Certificates.
# However, extraordinarily, PowerShell has no good way of disabling WOW64
# registry redirection(!!). Thus PowerShell's nativity to the registry nexus,
# its ability to manipulate the registry just like the filesystem, via 'cd
# HKLM:\...', etc. goes to waste.
#
# In order to access a specific 'view' of the registry (64-bit or 32-bit) we
# need to use [Microsoft.Win32.RegistryKey]::OpenBaseKey. This is only
# available in .NET 4 and later. PowerShell 2 uses .NET 2, not .NET 4. Only
# PowerShell 2 is guaranteed to be available on Windows 7. Thus, there is
# seemingly no actual way to access alternate views using the PowerShell which
# ships with Windows 7.
#
# So we have to execute powershell twice, once with the 32-bit version of
# powershell, and one with the 64-bit version of powershell. This is done in
# regpermrun.ps1.
#
# The following code will access the Wow6432Node view when run under 32-bit
# PowerShell on a 64-bit system and the non-Wow6432Node view otherwise.
cd HKLM:\Software\Microsoft\EnterpriseCertificates\Root\Certificates\
$acl = get-acl .

$inhFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
$rule = new-object System.Security.AccessControl.RegistryAccessRule("NT SERVICE\ncdns", "FullControl", $inhFlags, "None", "Allow")

if ($args[0] -eq "uninstall") {
  # Removes all rules with the same user and outcome (allow/deny)
  $acl.RemoveAccessRuleAll($rule)
} else {
  $acl.SetAccessRule($rule)
}
$acl | set-acl .
