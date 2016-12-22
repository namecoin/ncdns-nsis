# This script must be executed with powershell.exe -sta

$htmlFile = $args[0]
$confirmFile = $args[1]

Add-Type -AssemblyName System.Windows.Forms
$form = New-Object System.Windows.Forms.Form
$webBrowser = New-Object System.Windows.Forms.WebBrowser
$form.Controls.Add($webBrowser)
$form.Width = 800
$form.Height = 600

$webBrowser.Navigate($htmlFile)
$form.Add_Closing({
  [System.Windows.Forms.Application]::Exit()
  Stop-Process $pid
})
$form.Add_Resize({
  $webBrowser.Size = $form.ClientSize
})
$webBrowser.Add_DocumentTitleChanged({
  if ($webBrowser.DocumentTitle -eq "CMD_CONFIRMED") {
    echo CONFIRMED | Out-File $confirmFile
    [System.Windows.Forms.Application]::Exit()
    Stop-Process $pid
  } elseif ($webBrowser.DocumentTitle -eq "CMD_REJECTED") {
    [System.Windows.Forms.Application]::Exit()
    Stop-Process $pid
  } else {
    $form.Text = $webBrowser.DocumentTitle
  }
})
$webBrowser.Size = $form.ClientSize
$form.Show()
$form.Activate()
$ctx = (New-Object System.Windows.Forms.ApplicationContext)
[void][System.Windows.Forms.Application]::Run($ctx)
