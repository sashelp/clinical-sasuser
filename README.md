# Clinical SAS User

SAS programming resources and the **SAS/HELP** visual reference site.

## Contents

| Path | Description |
| --- | --- |
| [`codehub/macro/dev/`](codehub/macro/dev/) | SAS macro source library |
| [`codehub/macro/qc/`](codehub/macro/qc/) | Macro acceptance tests and test harness |
| [`codehub/Gallery/`](codehub/Gallery/) | SAS graph programs and example outputs |
| [`codehub/Script/`](codehub/Script/) | Utility scripts and bundled tools |
| [`sashelp/`](sashelp/) | Static documentation site, gallery, and macro reference |

`Gallery` and `Script` retain their existing directory names as requested.
The other directory names use lowercase spelling.

## Visual site

The published site is available at
[sashelp.github.io/clinical-sasuser](https://sashelp.github.io/clinical-sasuser/).
The site source and generated pages are kept in [`sashelp/`](sashelp/).

To check or rebuild the site on Windows, run from the repository root:

```powershell
.\sashelp\build\build.ps1 -Check
.\sashelp\build\build.ps1
```

The build reads macro sources from `codehub/macro/dev/` and writes generated
site files under `sashelp/`.

## Macro quality checks

The acceptance harness uses SAS 9.4. Set `SAS_EXE` to the local SAS executable
and `SAS_CFG` to a local SAS configuration file before running tests:

```powershell
$env:SAS_EXE = 'sas.exe'
$env:SAS_CFG = '.\path\to\sasv9.cfg'
.\codehub\macro\qc\run_all.ps1 -List
.\codehub\macro\qc\run_all.ps1 -Macro stat_summaryc
```

Use local settings appropriate to your SAS installation; do not commit
installation-specific configuration or license information.

## Copyright and license

This repository is distributed under the MIT License; see [`LICENSE`](LICENSE).
Third-party tools or bundled components remain subject to any applicable
upstream license terms. The SAS-generated `sasmacr.sas7bcat` catalog is not
included because it embeds a SAS installation path and is not project-owned
source.
