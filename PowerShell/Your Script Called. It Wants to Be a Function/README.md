# Your Script Called. It Wants to Be a Function.

You know how to write a PowerShell script. You know how to use dbatools. But every time you need the same logic in a different place, you copy and paste — and then you have two scripts to maintain. Then five. Then twenty.

This session is about breaking that habit. We will build a real, production-ready function from scratch — live, in front of you — one concept at a time. By the end, you will have a `Get-SQLServerInventory` function that interrogates every SQL Server instance in your registered server group, produces a full configuration inventory, handles a dead server without crashing the run, and formats straight into a table you can paste into an email. No hardcoded instance names. No copy-paste. One function, every server.

## What You Will Learn

- How `param()` blocks, type constraints, and default values work
- What `[DbaInstance]` is and why it beats `[string]` for SQL Server work
- How `[CmdletBinding()]` gives your function `-Verbose`, `-Debug`, `-WhatIf`, and `-Confirm` for free — and how `SupportsShouldProcess` adds `-WhatIf`/`-Confirm` to a function that changes something
- How parameter attributes (`Mandatory`, `ValidateSet`, `ValidateRange`, `ValidateScript`, `ValidateNotNullOrEmpty`) enforce correctness at the boundary — before a single connection is made
- How `ValueFromPipeline` and `[Alias()]` let `Get-DbaRegisteredServer | Get-SQLServerInventory` just work
- How `Begin` / `Process` / `End` blocks control the pipeline lifecycle — and what silently goes wrong when you skip `process` (only the last piped item ever gets processed)
- How `Try` / `Catch` and `-EnableException` / `-ErrorAction Stop` keep a dead server from killing your entire report, and how `$Error` lets you inspect what went wrong

## Prerequisites

The following PowerShell modules must be installed before the demos:

```powershell
Install-Module dbatools -Scope CurrentUser
```

A registered server group named **Demo** must exist in SSMS or via dbatools with at least two SQL Server instances registered (one demo also references a `StackOverflow2010` database on the first instance).

## Demo Overview

| File | Topic | Function version |
|---|---|---|
| `Demo1-WhyFunctions.ps1` | The copy/paste problem, registered servers, the payoff preview, functions as first-class citizens | Skeleton |
| `Demo2-ParamBlocks.ps1` | Untyped vs. typed params, `[DbaInstance]`, `Mandatory`, parameter sets and defaults, `Connect-DbaInstance` and the SMO server object | v1 — 4 columns (ComputerName, SqlInstance, Edition, Build) |
| `Demo3-CmdletBinding.ps1` | `[CmdletBinding()]`, `-Verbose`, `-Debug`, `SupportsShouldProcess` (`-WhatIf`/`-Confirm`) | v2 — full inventory (13 columns) |
| `Demo4-ParameterAttributes.ps1` | `ValidateSet`, `ValidateRange`, `ValidateScript`, `ValidateNotNullOrEmpty` | v3 — validated params |
| `Demo5-PipelineSupport.ps1` | `ValueFromPipeline`, the process-block gotcha (only the last piped item runs), `[Alias()]`, `Begin`/`Process`/`End` | v4 — pipeline support, same 13 columns per instance |
| `Demo6-ErrorHandling.ps1` | `Try`/`Catch`, `-EnableException`, `-ErrorAction Stop`, `$Error` | v5 — expanded inventory (18 columns) with per-instance error handling |

## What the Final Function Produces

`Get-SQLServerInventory` collects the following for every instance piped to it, skipping (and logging an error for) any instance it can't connect to rather than stopping the whole run:

- ServerName, InstanceName, SQLVersion, ServicePackLevel, UpdateKBLevel, Edition, OSVersion
- TraceFlags, NumberOfCores, NumberOfProcessors
- MaxDegreeOfParallelism, CostThresholdForParallelism, ServerMemory, MaxMemorySetting
- IsHadrEnabled, LoginMode
- DataPath, LogPath, BackupPath

```powershell
$report = Get-DbaRegisteredServer -Group Demo | Get-SQLServerInventory -Verbose

# view in the console
$report | Format-Table -AutoSize

# copy as plain text - paste straight into an email
$report | Format-Table -AutoSize
```

## Key Take-Aways from your session

- **Copy-paste is the warning sign.** The moment you reuse the same block of script logic against a second server, that block wants to be a function — a `param()` block is cheaper than maintaining two scripts.
- **Type your parameters.** `[DbaInstance]` (not `[string]`) accepts a server name, a SMO object, or a connection — and rejects garbage before you ever open a connection.
- **`[CmdletBinding()]` is nearly free.** One attribute gives every function `-Verbose` and `-Debug`; adding `SupportsShouldProcess` gets you `-WhatIf` and `-Confirm` too — instrumentation and safety you didn't have to write.
- **Validate at the boundary, not in the body.** `Mandatory`, `ValidateSet`, `ValidateRange`, `ValidateScript`, and `ValidateNotNullOrEmpty` catch bad input before a single connection is made, so your `Process` block only ever deals with clean data.
- **Pipeline support turns a function into a filter.** `ValueFromPipeline` and `[Alias()]` are what let `Get-DbaRegisteredServer | Get-SQLServerInventory` just work — no manual loop required.
- **Never skip the `Process` block.** Without it, a pipelined function silently runs its body only once, against the last object — one of the easiest and most invisible pipeline bugs to write.
- **One dead server should not kill the whole report.** `Try`/`Catch` with `-EnableException` (dbatools) and `-ErrorAction Stop` (built-in cmdlets) turns a hard failure on one instance into a logged error and a report that still finishes for the rest.
- **The payoff is real, not theoretical.** One `Get-SQLServerInventory` function, fed by a registered server group, replaces N ad hoc scripts and produces a single, complete inventory report you can format and paste anywhere.
