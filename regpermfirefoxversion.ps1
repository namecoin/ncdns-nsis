cd "HKLM:\Software\Mozilla\Mozilla Firefox\"
$acl = get-acl .

$inhFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit
$rule = new-object System.Security.AccessControl.RegistryAccessRule("NT SERVICE\ncdns", "ReadKey", $inhFlags, "None", "Allow")

if ($args[0] -eq "uninstall") {
  # Removes all rules with the same user and outcome (allow/deny)
  $acl.RemoveAccessRuleAll($rule)
} else {
  $acl.SetAccessRule($rule)
}
$acl | set-acl .
