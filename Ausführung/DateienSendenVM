Copy-VMFile -VMName "*Win11ProTestUmgebung*" `
    -SourcePath "C:\Users\Debeka\IdeaProjects\PowerShell.zip" `
    -DestinationPath "C:\Users\Win11ProTest\Desktop\PowerShell.zip" `
    -CreateFullPath `
    -FileSource Host

# Hyper-V Local Account bei Installation
start ms-cxh:localonly

#Export GPO
Backup-GPO -Name "MeineTestGPO" -Path "C:\GPO-Backups"

#Import GPO
Import-GPO -BackupGpoName "MeineTestGPO" -Path "C:\GPO-Backups" -TargetName "MeineTestGPO"