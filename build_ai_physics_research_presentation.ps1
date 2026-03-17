$ErrorActionPreference = "Stop"

function New-RgbColor([int]$r, [int]$g, [int]$b) {
    return $r + (256 * $g) + (65536 * $b)
}

$NAVY = New-RgbColor 12 22 46
$MIDNIGHT = New-RgbColor 20 32 62
$SLATE = New-RgbColor 34 47 84
$TEAL = New-RgbColor 28 182 164
$GOLD = New-RgbColor 232 181 74
$CORAL = New-RgbColor 234 111 92
$PALE = New-RgbColor 244 246 250
$MUTED = New-RgbColor 180 190 210
$WHITE = New-RgbColor 255 255 255
$SUCCESS = New-RgbColor 93 197 137
$WARNING = New-RgbColor 246 193 81

$ppAlignLeft = 1
$ppAlignCenter = 2
$ppAlignRight = 3
$msoTextOrientationHorizontal = 1
$msoShapeRectangle = 1
$msoShapeRoundedRectangle = 5
$ppLayoutBlank = 12

function Set-SlideTheme($slide, [int]$bgColor) {
    $slide.FollowMasterBackground = 0
    $slide.Background.Fill.Solid()
    $slide.Background.Fill.ForeColor.RGB = $bgColor

    $band = $slide.Shapes.AddShape($msoShapeRectangle, 0, 0, 960, 20)
    $band.Fill.Solid()
    $band.Fill.ForeColor.RGB = $GOLD
    $band.Line.Visible = 0

    $accent = $slide.Shapes.AddShape($msoShapeRectangle, 768, 20, 192, 9)
    $accent.Fill.Solid()
    $accent.Fill.ForeColor.RGB = $TEAL
    $accent.Line.Visible = 0
}

function Add-TextBoxSimple($slide, [float]$left, [float]$top, [float]$width, [float]$height, [string]$text, [int]$fontSize, [int]$color, [string]$fontName = "Aptos", [bool]$bold = $false, [int]$align = 1) {
    try {
        $tb = $slide.Shapes.AddTextbox($msoTextOrientationHorizontal, $left, $top, $width, $height)
    } catch {
        throw "AddTextbox failed: left=$left top=$top width=$width height=$height text=$text"
    }
    $tb.TextFrame.TextRange.Text = $text
    $tb.TextFrame.TextRange.Font.Name = $fontName
    $tb.TextFrame.TextRange.Font.Size = $fontSize
    $tb.TextFrame.TextRange.Font.Bold = $(if ($bold) { -1 } else { 0 })
    $tb.TextFrame.TextRange.Font.Color.RGB = $color
    $tb.TextFrame.TextRange.ParagraphFormat.Alignment = $align
    $tb.TextFrame.WordWrap = -1
    $tb.Line.Visible = 0
    return $tb
}

function Add-Panel($slide, [float]$left, [float]$top, [float]$width, [float]$height, [string]$title, [string[]]$bodyLines, [int]$fillColor, [int]$titleColor = $WHITE, [int]$bodyColor = $PALE, [int]$lineColor = $MIDNIGHT) {
    $shape = $slide.Shapes.AddShape($msoShapeRoundedRectangle, $left, $top, $width, $height)
    $shape.Fill.Solid()
    $shape.Fill.ForeColor.RGB = $fillColor
    $shape.Line.Visible = -1
    $shape.Line.ForeColor.RGB = $lineColor
    $shape.Line.Weight = 1.25

    Add-TextBoxSimple $slide ($left + 10) ($top + 8) ($width - 20) 22 $title 15 $titleColor "Aptos" $true $ppAlignLeft | Out-Null
    if ($bodyLines.Count -gt 0) {
        $bodyText = ($bodyLines | ForEach-Object { "- $_" }) -join "`r`n"
        Add-TextBoxSimple $slide ($left + 10) ($top + 33) ($width - 20) ($height - 40) $bodyText 11 $bodyColor "Aptos" $false $ppAlignLeft | Out-Null
    }
}

function Add-QuoteCard($slide, [float]$left, [float]$top, [float]$width, [float]$height, [string]$quote, [string]$outcome, [int]$accentColor) {
    $shape = $slide.Shapes.AddShape($msoShapeRoundedRectangle, $left, $top, $width, $height)
    $shape.Fill.Solid()
    $shape.Fill.ForeColor.RGB = $SLATE
    $shape.Line.Visible = -1
    $shape.Line.ForeColor.RGB = $accentColor
    $shape.Line.Weight = 2

    $stripe = $slide.Shapes.AddShape($msoShapeRectangle, $left, $top, 8, $height)
    $stripe.Fill.Solid()
    $stripe.Fill.ForeColor.RGB = $accentColor
    $stripe.Line.Visible = 0

    if ($height -lt 52) {
        Add-TextBoxSimple $slide ($left + 16) ($top + 8) ($width - 24) ($height - 14) ($quote + ": " + $outcome) 11 $PALE "Aptos" $false $ppAlignLeft | Out-Null
    } else {
        Add-TextBoxSimple $slide ($left + 16) ($top + 8) ($width - 24) 28 ('"' + $quote + '"') 12 $WHITE "Aptos" $true $ppAlignLeft | Out-Null
        Add-TextBoxSimple $slide ($left + 16) ($top + 38) ($width - 24) ($height - 42) $outcome 11 $PALE "Aptos" $false $ppAlignLeft | Out-Null
    }
}

function Add-Footer($slide, [int]$pageNum) {
    Add-TextBoxSimple $slide 590 505 330 18 ("ORBIT case study | Slide {0}" -f $pageNum) 10 $MUTED "Aptos" $false $ppAlignRight | Out-Null
}

function Add-ArrowLine($slide, [float]$x1, [float]$y1, [float]$x2, [float]$y2, [int]$color) {
    $line = $slide.Shapes.AddLine($x1, $y1, $x2, $y2)
    $line.Line.ForeColor.RGB = $color
    $line.Line.Weight = 2
    return $line
}

function Add-BarChartSlide($slide, [float]$left, [float]$top, [float]$width, [float]$height, [object[]]$items, [string]$title) {
    Add-Panel $slide $left $top $width $height $title @() $SLATE
    $maxVal = ($items | Measure-Object -Property Seconds -Maximum).Maximum
    $rowTop = $top + 50
    foreach ($item in $items) {
        Add-TextBoxSimple $slide ($left + 18) $rowTop 135 18 $item.Label 11 $PALE "Aptos" $false $ppAlignLeft | Out-Null
        $barWidth = [Math]::Max(16, (250 * $item.Seconds / $maxVal))
        $bar = $slide.Shapes.AddShape($msoShapeRoundedRectangle, ($left + 155), ($rowTop + 2), $barWidth, 13)
        $bar.Fill.Solid()
        $bar.Fill.ForeColor.RGB = $item.Color
        $bar.Line.Visible = 0
        Add-TextBoxSimple $slide ($left + 420) $rowTop 60 18 ("{0:N1}s" -f $item.Seconds) 11 $MUTED "Aptos" $false $ppAlignLeft | Out-Null
        $rowTop += 34
    }
}

$outFile = Join-Path $PSScriptRoot "AI_for_Physics_and_Math_Research_ORBIT_Case_Study.pptx"
$pp = New-Object -ComObject PowerPoint.Application
$pp.Visible = 1
$presentation = $pp.Presentations.Add()
$presentation.PageSetup.SlideWidth = 960
$presentation.PageSetup.SlideHeight = 540

$slide = $presentation.Slides.Add(1, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 48 76 860 54 "AI as a Research Accelerator in Physics and Mathematics" 26 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-TextBoxSimple $slide 48 124 860 42 "A case study from ORBIT: operator bases, IBP and field-redefinition reduction, Matchete translation, and Einstein-Hilbert matching" 16 $MUTED "Aptos" $false $ppAlignLeft | Out-Null
Add-Panel $slide 56 220 390 192 "Thesis" @(
    "Agentic AI is most valuable when the task is a long chain of reasoning, code repair, symbolic computation, validation, and reporting.",
    "This ORBIT project is a concrete example: the agent repaired a graviton-basis toolkit, built a comparison package, validated it, accelerated the workflow, and clarified the physics."
) $SLATE
Add-Panel $slide 476 220 420 192 "Core result" @(
    "The Matchete-derived result can be reduced and compared systematically to Einstein-Hilbert plus cosmological constant.",
    "At d <= 5 it matches a sign-flipped EH convention before canonical normalization; at d <= 6 a leftover {2,4} sector obstructs a pure EH+Lambda interpretation."
) $MIDNIGHT $GOLD
Add-Footer $slide 1

$slide = $presentation.Slides.Add(2, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "1. Mathematical and Physical Background" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-TextBoxSimple $slide 40 77 860 24 "The ORBIT package works in abstract-index xAct syntax and classifies graviton operators by field number and derivative count." 12 $MUTED "Aptos" $false $ppAlignLeft | Out-Null
Add-TextBoxSimple $slide 52 118 392 190 @"
- Sector notation: V_{n_h,N_d} collects scalar operators built from n_h gravitons and N_d derivatives.
- Reduction step 1: quotient by integration by parts (IBP).
- Reduction step 2: quotient by the image of field redefinitions in interaction sectors.
- Quadratic sectors are treated separately because naive redefinition quotienting can remove the kinetic term itself.
"@ 15 $PALE "Aptos" $false $ppAlignLeft | Out-Null
Add-Panel $slide 500 120 390 90 "Key quotient picture" @("Raw operators -> modulo IBP -> modulo field redefinitions -> physical coordinates") $TEAL $NAVY $NAVY $TEAL
Add-Panel $slide 500 225 390 170 "Reference action used in the comparison package" @(
    "L_ref = Lambda_ref sqrt(-g) + s_EH (2/kappa_ref^2) sqrt(-g) R",
    "mostly-minus convention, with metric perturbation g = eta + kappa h",
    "Comparison is done sector-by-sector in the same reduced basis as the translated Matchete output."
) $SLATE
Add-Footer $slide 2

$slide = $presentation.Slides.Add(3, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "2. Stating the Problem" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-Panel $slide 48 104 864 74 "Research question" @(
    "Can we take a Matchete-generated effective Lagrangian, translate it into xAct, remove IBP and field-redefinition redundancies, construct the Einstein-Hilbert reference through the same operator basis, and determine whether the two match?"
) $TEAL $NAVY $NAVY $TEAL

$stages = @(
    @{ X = 58; Title = "Matchete .mx"; Body = "Load the stored symbolic output" },
    @{ X = 210; Title = "Translation"; Body = "Map Matchete syntax to ORBIT/xAct" },
    @{ X = 362; Title = "Normalization"; Body = "Set hbar -> 1 and keep the finite epsilon^0 part" },
    @{ X = 514; Title = "Reduction"; Body = "Remove IBP and field-redefinition redundancies" },
    @{ X = 666; Title = "Reference build"; Body = "Expand EH + Lambda in the same basis" },
    @{ X = 818; Title = "Comparison"; Body = "Solve constraints and isolate leftovers" }
)
foreach ($stage in $stages) {
    Add-Panel $slide $stage.X 210 120 136 $stage.Title @($stage.Body) $SLATE
}
for ($i = 0; $i -lt ($stages.Count - 1); $i++) {
    Add-ArrowLine $slide ($stages[$i].X + 120) 278 ($stages[$i + 1].X) 278 $GOLD | Out-Null
}
Add-Panel $slide 230 384 500 58 "" @("Success criterion: equality in supported sectors, no unsupported leftovers, and a clear statement of the required parameter constraints and conventions.") $CORAL
Add-Footer $slide 3

$slide = $presentation.Slides.Add(4, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "3. The Challenges in Solving This Problem" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
$cards = @(
    @{ X = 52; Y = 112; Title = "Tensor syntax fragility"; Body = "Both kernels initially failed with syntax issues. Small xAct mistakes can invalidate long symbolic runs." },
    @{ X = 328; Y = 112; Title = "Basis ambiguity"; Body = "Notebook conventions and package conventions differed. Some counts changed depending on whether hh(ddh) was reduced correctly by IBP." },
    @{ X = 604; Y = 112; Title = "Quadratic-sector subtlety"; Body = "Field redefinitions at quadratic order can quotient out the kinetic term itself unless handled carefully." },
    @{ X = 52; Y = 288; Title = "Canonical normalization"; Body = "Matching depends on whether one normalizes to +L_FP or allows a sign-flipped kinetic convention." },
    @{ X = 328; Y = 288; Title = "Performance"; Body = "xPert expansion, ToCanonical, SolveConstants, and basis projection are expensive and mostly single-kernel bottlenecks." },
    @{ X = 604; Y = 288; Title = "Scientific traceability"; Body = "Every claim needed a reproducible check: saved scripts, cached runs, reports, and consistency tests." }
)
foreach ($card in $cards) {
    Add-Panel $slide $card.X $card.Y 250 132 $card.Title @($card.Body) $SLATE
}
Add-Footer $slide 4

$slide = $presentation.Slides.Add(5, $ppLayoutBlank)
Set-SlideTheme $slide $MIDNIGHT
Add-TextBoxSimple $slide 40 44 860 36 "4. The Recent Boom in Agentic AI Usage" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-Panel $slide 52 112 262 190 "What changed" @(
    "Recent systems are not just text generators. They search, read, execute code, keep state, and iterate across long tasks.",
    "The useful abstraction is an agent: a model with tools, persistence, and the ability to plan and validate intermediate steps."
) $SLATE
Add-Panel $slide 350 112 262 190 "Capabilities that matter for research" @(
    "Codebase archaeology and repair",
    "Symbolic debugging with external tools",
    "Experiment orchestration and caching",
    "Long-horizon state tracking through context files and result artifacts",
    "Automatic report and presentation generation"
) $TEAL $NAVY $NAVY $TEAL
Add-Panel $slide 648 112 262 190 "External signals" @(
    "OpenAI's deep research workflow explicitly targets multistep internet research and synthesis.",
    "OpenAI's 2025 scientific-research evaluation framed agentic systems as end-to-end scientific assistants, not just answer engines."
) $SLATE
Add-Panel $slide 52 330 858 70 "Primary sources used for this slide" @(
    "OpenAI: Introducing deep research (Feb. 2, 2025). OpenAI: Evaluating AI's ability to perform scientific research tasks (Dec. 16, 2025)."
) $MIDNIGHT $GOLD
Add-Footer $slide 5

$slide = $presentation.Slides.Add(6, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "Physics-Driven AI Research: Why This Matters Here" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-Panel $slide 52 104 858 64 "" @("This project is not generic AI for coding. It is AI used in a physics workflow: tensor conventions, operator bases, perturbative gravity, canonical normalization, and symbolic equivalence modulo redundancies.") $TEAL $NAVY $NAVY $TEAL
$timelineCards = @(
    @{ X = 68; Title = "Feb. 2025 | Deep research"; Body = "General multistep retrieval, synthesis, and tool use." },
    @{ X = 286; Title = "Dec. 2025 | Scientific research evaluation"; Body = "Benchmarks aimed at long-horizon research tasks." },
    @{ X = 504; Title = "Feb. 2026 | GPT-5.2 derives a new result in theoretical physics"; Body = "OpenAI highlighted genuine physics reasoning on scattering-amplitude problems." },
    @{ X = 722; Title = "Mar. 2026 | Extending single-minus amplitudes to gravitons"; Body = "A second QFT-focused result, now explicitly in gravity amplitudes." }
)
foreach ($card in $timelineCards) {
    Add-Panel $slide $card.X 196 178 182 $card.Title @($card.Body) $SLATE
}
Add-Panel $slide 70 408 840 54 "" @("Relevance to ORBIT: the same agentic pattern applies to perturbative gravity packages - read code, fix conventions, run the kernels, compare mathematical branches, and preserve an audit trail.") $CORAL
Add-Footer $slide 6

$slide = $presentation.Slides.Add(7, $ppLayoutBlank)
Set-SlideTheme $slide $MIDNIGHT
Add-TextBoxSimple $slide 40 44 860 36 "5. How We Can Use Agentic AI for This Problem" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-Panel $slide 52 112 190 80 "Task layer" @() $TEAL $NAVY $NAVY $TEAL
Add-Panel $slide 250 112 210 80 "What the agent does" @() $SLATE
Add-Panel $slide 468 112 220 80 "Why it is useful here" @() $SLATE
Add-Panel $slide 696 112 214 80 "What still needs human judgment" @() $SLATE
$rows = @(
    @("Code", "Patch syntax, add APIs, create drivers", "The package evolved while the mathematics was being clarified", "Choose the right conventions and what should count as physical"),
    @("Physics", "Check sector counts, compare notebook and package logic", "The hard part is often conceptual mismatch, not just a bug", "Interpret whether a mismatch is real or only conventional"),
    @("Performance", "Time runs, cache expensive sectors, isolate bottlenecks", "The symbolic stack is slow and fragile; targeted acceleration matters", "Decide which approximations or branch tests are worth running"),
    @("Reporting", "Generate reports, scripts, and presentation artifacts", "Research claims need to be inspectable and shareable", "Decide what is publishable, provisional, or stale")
)
$y = 200
foreach ($row in $rows) {
    Add-Panel $slide 52 $y 190 66 $row[0] @() $MIDNIGHT
    Add-Panel $slide 250 $y 210 66 "" @($row[1]) $SLATE
    Add-Panel $slide 468 $y 220 66 "" @($row[2]) $SLATE
    Add-Panel $slide 696 $y 214 66 "" @($row[3]) $SLATE
    $y += 74
}
Add-Footer $slide 7

$slide = $presentation.Slides.Add(8, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "6. Case Study Part I: Repair the ORBIT Core" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-QuoteCard $slide 52 114 258 124 "debug graviton_basis_toolkit.wl until it works and gives the expected output" "The agent fixed syntax issues, corrected derivative-partition logic, and made the basis-computation pipeline run again." $TEAL
Add-QuoteCard $slide 350 114 258 124 "doesn't fieldRedefinitionsAndIBP.nb provide different results?" "This forced a careful comparison between notebook conventions and the package's full sector generation. The discrepancy exposed an IBP canonicalization bug." $GOLD
Add-QuoteCard $slide 648 114 262 124 "the single graviton, 2 derivative terms have a physical count of 2, but isn't that a total derivative?" "The agent traced this to incomplete scalar-derivative canonicalization and fixed the {1,2} sector so it vanished modulo IBP as it should." $TEAL
Add-Panel $slide 52 276 858 162 "Successful physics-guided code changes" @(
    "Restored scalar-derivative commutation and derivative sorting in the IBP path.",
    "Corrected the interpretation of SolveConstants[0 == 0] so trivial sectors do not masquerade as nontrivial.",
    "Changed the quadratic-sector policy so field-redefinition quotienting is skipped for n_h < 3.",
    "Validated corrected counts such as {3,2}: IBPCount = 14, RedefRank = 4, PhysicalCount = 10."
) $SLATE
Add-Footer $slide 8

$slide = $presentation.Slides.Add(9, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "Case Study Part II: Build a General Reduction and Validation Workflow" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-QuoteCard $slide 52 114 258 124 "write a new code that takes a lagrangian and removes the ibp and field-redefinition redundancies" "The agent added a reducer API that splits an input by sector, projects it onto the raw basis, removes IBP, and then quotients by redefinition images where appropriate." $TEAL
Add-QuoteCard $slide 350 114 258 124 "test the new code by taking a lagrangian which is the EOM times some general lagrangian" "The agent built disguised EOM-image tests in {3,2} and {3,4}; both reduced exactly to zero, confirming the implementation." $SUCCESS
Add-QuoteCard $slide 648 114 262 124 "create a comprehensive report ... mathematical background, validation, and a worked example" "The agent generated notebooks, PDFs, and a paper-style LaTeX report documenting the toolkit, algorithms, and validation logic." $GOLD
Add-Panel $slide 52 276 858 162 "Concrete validation outputs" @(
    "Reduction API exercised on mixed sectors and on redundant EOM images.",
    "Persistent validation scripts, PDF reports, and context tracking were added so crashes would not erase state.",
    "The translated LEFT_only_uv_2_eft_6 xAct input reduced from 1725 raw terms to 202 reduced terms across 10 surviving sectors."
) $SLATE
Add-Footer $slide 9

$slide = $presentation.Slides.Add(10, $ppLayoutBlank)
Set-SlideTheme $slide $MIDNIGHT
Add-TextBoxSimple $slide 40 44 860 36 "Case Study Part III: ORBIT_BUILD and the Fixed-EH Comparison" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-QuoteCard $slide 52 114 258 124 "continue according to the ORBIT_BUILD fixed-EH comparison plan" "The agent vendored the translator, built the comparison package, added staged checkpointing, and created a live ORBIT_BUILD context file." $TEAL
Add-QuoteCard $slide 350 114 258 124 "let's speed up the computation as much as possible" "The agent identified xPert expansion and basis projection as the bottlenecks, added disk caching for the reference expansion, and removed redundant canonicalization." $GOLD
Add-QuoteCard $slide 648 114 262 124 "did you consider canonical normalization?" "The agent derived the exact kinetic prefactor Z_h, separated raw matching from canonically normalized matching, and exposed a genuine sign-convention branch." $CORAL
Add-Panel $slide 52 276 858 172 "Final branch analysis" @(
    "Before canonical normalization, the d <= 5 comparison matches a sign-flipped EH convention: s_EH = -1, Lambda_ref = 0, log(mu^2/M^2) = -3/2, M^2 kappa^2 = 48, and kappa_ref = kappa.",
    "At full d <= 6, the comparison still leaves an unsupported {2,4} sector, so the result is not pure EH + Lambda.",
    "With the current canonical-normalization step enabled, the sign-flipped branch no longer matches because the input is normalized to +L_FP while the reference quadratic sector is -L_FP."
) $SLATE
Add-Footer $slide 10

$slide = $presentation.Slides.Add(11, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "Measured Runtime and Bottlenecks" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
$barItems = @(
    [PSCustomObject]@{ Label = "Translation"; Seconds = 310.4; Color = $TEAL },
    [PSCustomObject]@{ Label = "Finite-part normalization"; Seconds = 306.5; Color = $TEAL },
    [PSCustomObject]@{ Label = "Reference expansion"; Seconds = 1466.9; Color = $GOLD },
    [PSCustomObject]@{ Label = "Input reduction"; Seconds = 1608.5; Color = $CORAL },
    [PSCustomObject]@{ Label = "Reference reduction"; Seconds = 675.8; Color = $GOLD },
    [PSCustomObject]@{ Label = "Comparison assembly"; Seconds = 546.6; Color = $TEAL }
)
Add-BarChartSlide $slide 52 112 470 264 $barItems "Measured full d <= 6 run: 4915 s total (~81.9 min)"
Add-Panel $slide 560 116 350 92 "Why it took so long" @("The dominant costs were xPert expansion, ToCanonical, SolveConstants, and projection onto large sector bases. xAct was effectively single-kernel in this workflow.") $SLATE
Add-Panel $slide 560 228 350 84 "After caching and scope reduction" @("The corrected d <= 5 rerun dropped to ~374 s (~6.2 min). The EHSign = -1 sign check without canonical normalization completed in ~8.3 min wall-clock.") $MIDNIGHT $GOLD
Add-Panel $slide 560 332 350 84 "AI contribution" @("The agent did not make xAct parallel, but it did make the workflow practical by profiling, caching, checkpointing, and narrowing expensive branches.") $TEAL $NAVY $NAVY $TEAL
Add-Footer $slide 11

$slide = $presentation.Slides.Add(12, $ppLayoutBlank)
Set-SlideTheme $slide $NAVY
Add-TextBoxSimple $slide 40 44 860 36 "Tests, Sanity Checks, and Scientific Guardrails" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
$checks = @(
    @{ Title = "Sector sanity"; Body = "Verified that the {1,2} sector vanishes modulo IBP after the canonicalization fix."; Color = $SUCCESS },
    @{ Title = "Notebook parity"; Body = "Resolved the cubic {3,2} mismatch by identifying the missing IBP reduction and clarifying restricted versus full-sector counting."; Color = $SUCCESS },
    @{ Title = "Redundant images"; Body = "Tested L = EOM . delta h with disguised expressions; the reducer returned zero."; Color = $SUCCESS },
    @{ Title = "Kinetic normalization"; Body = "Showed the Matchete {2,2} sector is exactly Z_h times the Fierz-Pauli kinetic term."; Color = $SUCCESS },
    @{ Title = "Reference consistency"; Body = "Checked that the EH {2,2} sector equals the toolkit's Fierz-Pauli Lagrangian in the same reduced basis."; Color = $SUCCESS },
    @{ Title = "Convention split"; Body = "Separated raw sign-convention matching from canonical-normalization matching; identified the unresolved kinetic-sign choice."; Color = $WARNING },
    @{ Title = "Unsupported leftovers"; Body = "At d <= 6 the full run still leaves a non-EH {2,4} sector."; Color = $WARNING }
)
$y = 100
foreach ($check in $checks) {
    Add-QuoteCard $slide 60 $y 850 34 $check.Title $check.Body $check.Color
    $y += 46
}
Add-Footer $slide 12

$slide = $presentation.Slides.Add(13, $ppLayoutBlank)
Set-SlideTheme $slide $MIDNIGHT
Add-TextBoxSimple $slide 40 44 860 36 "What the AI Actually Added, and What Comes Next" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-Panel $slide 52 112 250 222 "New package capabilities" @(
    "Matchete .mx -> xAct translator vendored into ORBIT",
    "General Lagrangian reducer modulo IBP and field redefinitions",
    "Fixed-EH comparison package with report generation",
    "Explicit EHSign option in the reference builder"
) $SLATE
Add-Panel $slide 326 112 270 222 "Successful AI-proposed ideas" @(
    "Skip field-redefinition quotienting in quadratic sectors",
    "Project to the raw basis first, then quotient by stored IBP relations",
    "Use exact epsilon^0 extraction rather than heuristic pole filtering",
    "Separate supported and unsupported sector comparisons"
) $TEAL $NAVY $NAVY $TEAL
Add-Panel $slide 620 112 290 222 "Next steps" @(
    "Add a kinetic-sign-aware canonical-normalization stage so +L_FP and -L_FP branches can be tested on equal footing.",
    "Extend the field-redefinition layer beyond the linearized Fierz-Pauli image.",
    "Add fixed-dimension identities, evanescent operators, and gauge-invariance filters."
) $SLATE
Add-Panel $slide 72 364 818 84 "Suggested framing for the talk" @("Present AI not as an oracle, but as a force multiplier for disciplined research: it accelerates debugging, experimentation, and documentation, while the human still decides the physics.") $CORAL
Add-Footer $slide 13

$slide = $presentation.Slides.Add(14, $ppLayoutBlank)
Set-SlideTheme $slide $MIDNIGHT
Add-TextBoxSimple $slide 40 44 860 36 "Sources and Artifacts" 24 $WHITE "Aptos Display" $true $ppAlignLeft | Out-Null
Add-Panel $slide 52 112 410 230 "Primary external sources" @(
    "OpenAI, Introducing deep research (Feb. 2, 2025)",
    "OpenAI, Evaluating AI's ability to perform scientific research tasks (Dec. 16, 2025)",
    "OpenAI, GPT-5.2 derives a new result in theoretical physics (Feb. 13, 2026)",
    "OpenAI, Extending single-minus amplitudes to gravitons (Mar. 4, 2026)"
) $SLATE
Add-Panel $slide 498 112 412 230 "Local ORBIT artifacts used in this talk" @(
    "graviton_basis_toolkit.wl",
    "orbit_fixed_eh_comparison.wl",
    "ORBIT_BUILD_CONTEXT.md",
    "LEFT_only_uv_2_eft_6_xact_reduction_summary.wl",
    "orbit_fixed_eh_comparison_d5_v3_result.wl",
    "orbit_fixed_eh_comparison_d5_free_ref_minus_eh_nocanon_result.wl"
) $SLATE
Add-Panel $slide 88 382 786 68 "" @("This deck was generated from build_ai_physics_research_presentation.ps1 so it can be revised and rebuilt as the package evolves.") $TEAL $NAVY $NAVY $TEAL
Add-Footer $slide 14

$presentation.SaveAs($outFile)
$presentation.Close()
$pp.Quit()

Write-Output "Wrote $outFile"
