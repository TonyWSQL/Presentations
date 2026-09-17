# Your Script Called. It Wants to Be a Function.

## Demo Description

These demos build a single function, `Get-SQLServerInventory`, incrementally across six files. Each demo starts from a copy/paste pain point and layers on one PowerShell function-authoring concept at a time, ending with a production-ready SQL Server inventory/health-check function that accepts pipeline input, validates its parameters, supports `-WhatIf`/`-Verbose`, and handles errors per-server without crashing the whole run.

1. **Demo1 - Why Functions**: Motivates the whole talk. Shows the copy/paste pain of running the same dbatools command against multiple servers by hand, then the "payoff" one-liner the talk builds toward, then introduces the bare function shell and shows PowerShell treats it like any other cmdlet.
2. **Demo2 - Param Blocks**: Builds up the parameter block from an untyped param, to a typed param (`[DbaInstance]`), to mandatory parameters, to parameter sets with a default value — then introduces the SMO server object via `Connect-DbaInstance` and produces v1 of the function (structured identity data).
3. **Demo3 - CmdletBinding**: Shows what's missing without `[CmdletBinding()]` (no `-Verbose`, no common parameters), then adds it, layers in `Write-Debug`, and introduces `SupportsShouldProcess` for `-WhatIf`/`-Confirm` — then produces v2 of the function (full inventory report with verbose logging).
4. **Demo4 - Parameter Attributes**: Covers validation attributes — `ValidateSet` (tab completion + rejection), `ValidateRange` (numeric bounds), `ValidateScript` (custom logic), and `ValidateNotNullOrEmpty` — then produces v3 of the function with validated parameters.
5. **Demo5 - Pipeline Support**: Covers pipeline binding — `ValueFromPipeline`, the missing-`process`-block gotcha, `ValueFromPipelineByPropertyName` + `Alias`, and the full `begin`/`process`/`end` lifecycle — then produces v4 of the function, now accepting piped registered-server objects for a full multi-instance inventory.
6. **Demo6 - Error Handling**: Shows a single bad server crashing the whole pipeline with no error handling, then adds `try`/`catch` (with `-EnableException` for dbatools, `-ErrorAction Stop` for built-ins) so a bad server becomes an Error row instead of a crash — then produces v5, the final full health-report function, and closes with the payoff: one function, piped from registered servers, exported to Excel as both an inventory and a health report.

## Intro Slide Blurbs (one line per demo)

1. **Demo1 - Why Functions**: Copy/paste doesn't scale — meet the function we'll build.
2. **Demo2 - Param Blocks**: Give your function real inputs, not just guesses.
3. **Demo3 - CmdletBinding**: One line turns your function into a real cmdlet.
4. **Demo4 - Parameter Attributes**: Reject bad input before it ever runs.
5. **Demo5 - Pipeline Support**: Let PowerShell feed your function one item at a time.
6. **Demo6 - Error Handling**: One bad server shouldn't kill the whole report.

## Concepts (paired slides: Concept intro → Demo N)

Each topic below is two slides, matching the Intro to PowerShell deck pattern: a **concept slide** (title + bullets explaining the idea) followed by a **Demo N slide** (icon + short bullet list of what that demo shows).

### Why write functions at all
**Concept slide**
- Copy/paste doesn't scale
- Functions are first-class citizens
- Goal: reusable, pipeline-friendly

**Demo1 - Why Functions**
- The copy/paste problem
- The payoff one-liner
- Bare function shell

### Param blocks
**Concept slide**
- Names start with `$`, typed with `[Type]`
- Mandatory parameters
- Default values
- Parameter sets
- `$PSBoundParameters`

**Demo2 - Param Blocks**
- Untyped
- Typed (`[DbaInstance]`)
- Mandatory
- Parameter sets + default
- SMO server object

### `[CmdletBinding()]`
**Concept slide**
- Unlocks common parameters
- `Write-Verbose` / `Write-Debug`
- `SupportsShouldProcess`
- `-WhatIf` / `-Confirm`

**Demo3 - CmdletBinding**
- Without it (silent)
- With it (`-Verbose` works)
- `Write-Debug`
- `SupportsShouldProcess`

### Parameter validation attributes
**Concept slide**
- `ValidateSet`
- `ValidateRange`
- `ValidateScript`
- `ValidateNotNullOrEmpty`
- Fail at the boundary

**Demo4 - Parameter Attributes**
- Tab-complete + reject
- Numeric bounds
- Custom validation
- Empty/null rejection

### Pipeline support
**Concept slide**
- `ValueFromPipeline`
- `ValueFromPipelineByPropertyName` + `Alias`
- `begin` / `process` / `end`

**Demo5 - Pipeline Support**
- Single pipeline binding
- Missing `process` gotcha
- Alias + property binding
- Full lifecycle

### Error handling
**Concept slide**
- One bad item crashes all
- `try` / `catch`
- `-EnableException`
- `-ErrorAction Stop`
- `$Error` log

**Demo6 - Error Handling**
- No handling (crash)
- Try/catch (error row)
- `-ErrorAction Stop`
- Final health report

### The payoff
**Concept/closing slide**
- One-liner, all servers
- Console, clipboard, Excel
