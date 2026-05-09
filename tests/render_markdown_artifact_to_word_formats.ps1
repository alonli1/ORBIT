param(
  [Parameter(Mandatory = $false)]
  [string]$InputPath = "tests/artifacts/orbit_solution_case_end_to_end_derivation.md",

  [Parameter(Mandatory = $false)]
  [string]$HtmlPath = "",

  [Parameter(Mandatory = $false)]
  [string]$DocxPath = "",

  [Parameter(Mandatory = $false)]
  [string]$PdfPath = ""
)

$ErrorActionPreference = "Stop"

function Get-FullPath {
  param(
    [Parameter(Mandatory = $true)]
    [string]$PathValue
  )

  $resolved = Resolve-Path -LiteralPath $PathValue -ErrorAction Stop
  return $resolved.ProviderPath
}

function Convert-InlineMarkdownToHtml {
  param(
    [Parameter(Mandatory = $true)]
    [string]$Text
  )

  $segments = [regex]::Split($Text, '(`[^`]+`)')
  $builder = New-Object System.Text.StringBuilder

  foreach ($segment in $segments) {
    if ($segment -match '^`([^`]+)`$') {
      [void]$builder.Append("<code>")
      [void]$builder.Append([System.Net.WebUtility]::HtmlEncode($matches[1]))
      [void]$builder.Append("</code>")
      continue
    }

    $encoded = [System.Net.WebUtility]::HtmlEncode($segment)
    $encoded = [regex]::Replace($encoded, "\*\*(.+?)\*\*", "<strong>`$1</strong>")
    $encoded = [regex]::Replace($encoded, "\*(.+?)\*", "<em>`$1</em>")
    $encoded = [regex]::Replace(
      $encoded,
      "\[([^\]]+)\]\(([^)]+)\)",
      {
        param($match)
        $label = $match.Groups[1].Value
        $target = $match.Groups[2].Value
        if ($target -match "^/[A-Za-z]:/") {
          $target = "file:///" + ($target.TrimStart("/") -replace "\\", "/")
        }
        return "<a href=""$target"">$label</a>"
      }
    )
    [void]$builder.Append($encoded)
  }

  return $builder.ToString()
}

function Convert-MarkdownToHtmlDocument {
  param(
    [Parameter(Mandatory = $true)]
    [string]$MarkdownPath
  )

  $lines = Get-Content -LiteralPath $MarkdownPath
  $htmlLines = New-Object System.Collections.Generic.List[string]
  $paragraphBuffer = New-Object System.Collections.Generic.List[string]
  $codeBuffer = New-Object System.Collections.Generic.List[string]
  $inCodeBlock = $false
  $listType = $null

  function Flush-Paragraph {
    if ($paragraphBuffer.Count -gt 0) {
      $joined = ($paragraphBuffer -join " ").Trim()
      if ($joined.Length -gt 0) {
        $htmlLines.Add("<p>$(Convert-InlineMarkdownToHtml $joined)</p>")
      }
      $paragraphBuffer.Clear()
    }
  }

  function Flush-List {
    if ($null -ne $listType) {
      $htmlLines.Add("</$listType>")
      $script:listType = $null
    }
  }

  function Flush-CodeBlock {
    if ($inCodeBlock) {
      $encoded = [System.Net.WebUtility]::HtmlEncode(($codeBuffer -join [Environment]::NewLine))
      $htmlLines.Add("<pre><code>$encoded</code></pre>")
      $codeBuffer.Clear()
      $script:inCodeBlock = $false
    }
  }

  foreach ($line in $lines) {
    if ($line -match '^```') {
      Flush-Paragraph
      Flush-List
      if ($inCodeBlock) {
        Flush-CodeBlock
      } else {
        $inCodeBlock = $true
      }
      continue
    }

    if ($inCodeBlock) {
      $codeBuffer.Add($line)
      continue
    }

    if ($line -match "^\s*$") {
      Flush-Paragraph
      Flush-List
      continue
    }

    if ($line -match "^(#{1,6})\s+(.+)$") {
      Flush-Paragraph
      Flush-List
      $level = $matches[1].Length
      $text = Convert-InlineMarkdownToHtml $matches[2]
      $htmlLines.Add("<h$level>$text</h$level>")
      continue
    }

    if ($line -match "^\-\s+(.+)$") {
      Flush-Paragraph
      if ($listType -ne "ul") {
        Flush-List
        $listType = "ul"
        $htmlLines.Add("<ul>")
      }
      $htmlLines.Add("<li>$(Convert-InlineMarkdownToHtml $matches[1])</li>")
      continue
    }

    if ($line -match "^\d+\.\s+(.+)$") {
      Flush-Paragraph
      if ($listType -ne "ol") {
        Flush-List
        $listType = "ol"
        $htmlLines.Add("<ol>")
      }
      $htmlLines.Add("<li>$(Convert-InlineMarkdownToHtml $matches[1])</li>")
      continue
    }

    Flush-List
    $paragraphBuffer.Add($line.Trim())
  }

  Flush-Paragraph
  Flush-List
  Flush-CodeBlock

  $title = [System.IO.Path]::GetFileNameWithoutExtension($MarkdownPath)
  $body = $htmlLines -join [Environment]::NewLine

  return @"
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>$title</title>
  <style>
    body {
      font-family: Calibri, Arial, sans-serif;
      font-size: 11pt;
      line-height: 1.45;
      color: #222;
      margin: 0.8in;
    }
    h1, h2, h3, h4, h5, h6 {
      font-family: Cambria, "Times New Roman", serif;
      color: #16324f;
      margin-top: 18pt;
      margin-bottom: 8pt;
    }
    h1 { font-size: 22pt; }
    h2 { font-size: 17pt; }
    h3 { font-size: 14pt; }
    p {
      margin-top: 0;
      margin-bottom: 8pt;
    }
    ul, ol {
      margin-top: 0;
      margin-bottom: 10pt;
      padding-left: 22pt;
    }
    li {
      margin-bottom: 4pt;
    }
    code {
      font-family: Consolas, "Courier New", monospace;
      background: #f3f5f7;
      border: 1px solid #d6dbe1;
      border-radius: 3px;
      padding: 1px 4px;
      font-size: 9.5pt;
    }
    pre {
      font-family: Consolas, "Courier New", monospace;
      background: #f8f9fb;
      border: 1px solid #d6dbe1;
      padding: 10pt;
      white-space: pre-wrap;
      word-break: break-word;
      margin-top: 0;
      margin-bottom: 10pt;
      font-size: 9.5pt;
    }
    pre code {
      background: transparent;
      border: none;
      padding: 0;
      border-radius: 0;
    }
    a {
      color: #0b5cab;
      text-decoration: none;
    }
    a:hover {
      text-decoration: underline;
    }
  </style>
</head>
<body>
$body
</body>
</html>
"@
}

function Export-HtmlWithWord {
  param(
    [Parameter(Mandatory = $true)]
    [string]$SourceHtmlPath,

    [Parameter(Mandatory = $true)]
    [string]$TargetDocxPath,

    [Parameter(Mandatory = $true)]
    [string]$TargetPdfPath
  )

  $word = $null
  $document = $null

  try {
    $word = New-Object -ComObject Word.Application
    $word.Visible = $false
    $word.DisplayAlerts = 0

    $document = $word.Documents.Open($SourceHtmlPath)
    $document.SaveAs2([ref]$TargetDocxPath, [ref]16)
    $document.ExportAsFixedFormat($TargetPdfPath, 17)
  }
  finally {
    if ($null -ne $document) {
      $document.Close([ref]$false)
      [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($document)
    }
    if ($null -ne $word) {
      $word.Quit()
      [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($word)
    }
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
  }
}

$inputFull = Get-FullPath -PathValue $InputPath
$inputDirectory = Split-Path -Parent $inputFull
$baseName = [System.IO.Path]::GetFileNameWithoutExtension($inputFull)

if ([string]::IsNullOrWhiteSpace($HtmlPath)) {
  $HtmlPath = Join-Path $inputDirectory ($baseName + ".html")
}
if ([string]::IsNullOrWhiteSpace($DocxPath)) {
  $DocxPath = Join-Path $inputDirectory ($baseName + ".docx")
}
if ([string]::IsNullOrWhiteSpace($PdfPath)) {
  $PdfPath = Join-Path $inputDirectory ($baseName + ".pdf")
}

$htmlFull = [System.IO.Path]::GetFullPath($HtmlPath)
$docxFull = [System.IO.Path]::GetFullPath($DocxPath)
$pdfFull = [System.IO.Path]::GetFullPath($PdfPath)

$html = Convert-MarkdownToHtmlDocument -MarkdownPath $inputFull
Set-Content -LiteralPath $htmlFull -Value $html -Encoding UTF8

Export-HtmlWithWord -SourceHtmlPath $htmlFull -TargetDocxPath $docxFull -TargetPdfPath $pdfFull

Write-Host "Generated HTML: $htmlFull"
Write-Host "Generated DOCX: $docxFull"
Write-Host "Generated PDF:  $pdfFull"
