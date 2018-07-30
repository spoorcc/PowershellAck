Function ack() {
    <#
    .SYNOPSIS
    Powershell implementation of ack-grep tool
    .DESCRIPTION
    Search files and highlight matches just like grep but better. (www.beyondgrep.com)
    .EXAMPLE
    ack 'my search string'
    .EXAMPLE
    ack -noRecurse -ignoreCase 'MAX'
    .EXAMPLE
    ack -i 'MAX' *.h
    .PARAMETER noRecurse
    Search recursivly through underlying folders
    .PARAMETER ignoreCase
    Make the pattern ignore case
    .PARAMETER pattern
    Search pattern, can be a Regular Expression
    .PARAMETER path
    Optional file path (globbing supported) to search in.
    #>
    param(
        [Parameter(Mandatory=$false)][Alias("n")][switch]$noRecurse,
        [Parameter(Mandatory=$false)][Alias("i")][switch]$ignoreCase,
        [Parameter(Mandatory=$false)][string]$ignoreFile,
        [Parameter(Mandatory=$false)][switch]$l,
        [Parameter(Mandatory=$false)][switch]$cc,
        [Parameter(Mandatory=$false)][switch]$python,
        [Parameter(Mandatory=$true, Position=0)][string]$pattern,
        [Parameter(Mandatory=$false, Position=1)][string]$path
    )

    #$include = ("*")

    if ($cc) { $include = ("*.c", "*.cpp", "*.h", "*.xs") }
    if ($python) { $include = ("*.python") }

    $fileFindArgs = @{
      path = If ($path) {$path} else {"."}
      Recurse = -Not $noRecurse
      include = $include
    }
    $cleanedFileFindArgs = @{}
    $fileFindArgs.GetEnumerator()  | ? Value -NotIn ('', $null) | % { $cleanedFileFindArgs.Add($_.Key, $_.Value) }

    $selectStringArgs = @{
      pattern = $pattern
      caseSensitive = -Not $ignoreCase
      exclude = $ignoreFile
    }
    $cleanedSelectStringArgs = @{}
    $selectStringArgs.GetEnumerator()  | ? Value -NotIn ('', $null) | % { $cleanedSelectStringArgs.Add($_.Key, $_.Value) }

    # Do actual search
    $matches = (Get-Childitem @cleanedFileFindArgs | Select-String @cleanedSelectStringArgs )

    # Print matches per file
    $currentFile = ""

    foreach($match in $matches)
    {
       if( $currentFile -ne ($match.RelativePath((Get-Location).ToString())))
       {
           $currentFile = ($match.RelativePath((Get-Location).ToString()))
           if( -Not $l )
           {
               Write-Host ([string]::Format("{0}{1}:", [Environment]::NewLine, $currentFile)) -ForegroundColor Green
           } else {
               Write-Host $currentFile
           }
       }

       if( -Not $l )
       {
           Write-Host ([string]::Format("{0}:", $match.LineNumber)) -ForegroundColor Green -NoNewLine

           # Highlight all occurences of the pattern in the line
           $startIndex = 0

           foreach($subMatch in $match.Matches)
           {
              $nonMatchLength = $subMatch.Index - $startIndex
              Write-Host $match.Line.Substring($startIndex, $nonMatchLength) -NoNewLine
              Write-Host $subMatch.Value -Back DarkRed -NoNewLine
              $startIndex = $subMatch.Index + $subMatch.Length
           }

           if($startIndex -lt $match.Line.Length)
           {
              Write-Host $match.Line.Substring($startIndex) -NoNew
           }
           Write-Host
       }
    }
}
