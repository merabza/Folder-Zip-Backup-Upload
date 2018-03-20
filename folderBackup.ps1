param([string]$DbPath, [string]$checkFiles, [string]$prefix, [string]$backupFolder, [string]$ftpSite, [string]$user, [string]$pass)

#clear

$ZipFileExtension = ".zip"
$ZipFileDateTimeFormat = "yyyyMMddHHmmss"


$ZipFileName = $prefix + (Get-Date -Format $ZipFileDateTimeFormat) + $ZipFileExtension
$ZipFilePath = $backupFolder + $ZipFileName


#if ( (Test-Path  ($DbPath + $BaseProgName)) -and (Test-Path  ($DbPath + $BaseDataName)) )
if ( (Test-Path  ($DbPath + $checkFiles)) )
{
  echo("Files Exists")
}
else
{
  echo("Files MISSING!!!")
  exit 0
}  


"Compress Backupfile..."

Compress-Archive -LiteralPath $DbPath -DestinationPath $ZipFilePath


$webclient = New-Object System.Net.WebClient 
 
$webclient.Credentials = New-Object System.Net.NetworkCredential($user,$pass)  

"Uploading compressed Backupfile..." 
$uri = New-Object System.Uri($ftpSite + $ZipFileName) 


$webclient.UploadFile($uri, $ZipFilePath) 

"Remove compressed Backupfile..." 
Remove-Item $ZipFilePath



"Search and delete old files from ftp..." 
$webrequest =[system.net.ftpwebrequest][System.Net.FtpWebRequest]::Create($ftpSite)
$webRequest.Method = [system.net.WebRequestMethods+ftp]::listdirectorydetails
$webRequest.Credentials = New-Object System.Net.NetworkCredential($user,$pass)

$webResponse = [System.Net.FtpWebResponse]$webRequest.getresponse()

$streamResponse = $webResponse.getresponsestream();

$fileNames = New-Object System.Collections.ArrayList

if ( $streamResponse )
{
  $streamReader = New-Object System.IO.StreamReader($streamResponse)
  $str = $streamReader.ReadLine()
  while ($str)
  {
    #$str
    if (!$str.StartsWith("d"))
    {
      $fn = $str.Substring(56)
      if ( $fn.StartsWith($prefix) )
      {
        $fileNames.Add($fn) > $null
      }
    }
    $str = $streamReader.ReadLine()
  }
}



$previousmonth  = ((Get-Date).AddMonths(-1))
#$previousmonth
foreach ( $fn in $fileNames)
{
  
  $webrequest =[system.net.ftpwebrequest][System.Net.FtpWebRequest]::Create($ftpSite+$fn)
  $webRequest.Method = [system.net.WebRequestMethods+ftp]::GetDateTimestamp
  $webRequest.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
  $webResponse = [System.Net.FtpWebResponse]$webRequest.getresponse()
  if ( $webResponse.LastModified -lt $previousmonth )
  {
    $fn + " " + $webResponse.LastModified
    $webrequest =[system.net.ftpwebrequest][System.Net.FtpWebRequest]::Create($ftpSite+$fn)
    $webRequest.Method = [system.net.WebRequestMethods+ftp]::DeleteFile
    $webRequest.Credentials = New-Object System.Net.NetworkCredential($user,$pass)
    $webResponse = [System.Net.FtpWebResponse]$webRequest.getresponse()
    $webResponse.StatusDescription
  }

}


"Finish" 


 

