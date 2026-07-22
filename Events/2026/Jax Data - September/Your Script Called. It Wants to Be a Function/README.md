# Your Script Called. It Wants to Be a Function.

You know how to write a PowerShell script. You know how to use dbatools. But every time you need the same logic in a different place, you copy and paste — and then you have two scripts to maintain. Then five. Then twenty.

This session is about breaking that habit. We will build a real, production-ready function from scratch — live, in front of you — one concept at a time. By the end, you will have a `Get-SqlServerHealth` function that interrogates every SQL Server instance in your registered server group, produces a full inventory and health report, and pipes directly to Excel or your clipboard for an email. No hardcoded instance names. No copy-paste. One function, every server.