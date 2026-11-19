---
name: sas-macro-development
description: Use when authoring or maintaining this SAS macro library, excluding imported opensource macros.
---

# SAS Macro Development

Apply these conventions to macros authored for this library. The `opensource` directory contains imported or independently maintained code and is not a source of house-style requirements.

## Structure and documentation

- Target SAS 9.4M7 and preserve the library's existing macro naming and parameter conventions.
- Start a macro file with a block comment documenting `Brief`, required and optional parameters, details, notes, usage, dependencies, SAS version, and dated history. Keep parameter documentation aligned with actual defaults and accepted values.
- Add a macro `des=` description when it is useful, and use descriptive lower-case macro names with underscore-separated words.
- Organize the macro body into numbered sections: `1. Exception capture and handling`, `2. Core processing`, and, when useful, `3. Output and exit`.
- Declare macro working variables with `%local`; use names that make their purpose clear.

## Validation and errors

- Validate required parameters, dataset existence, variable existence/types, and enumerated values before doing the main work.
- Follow the established error path: set a descriptive `ERROR:` message in `errtext`, route to the `exception:` label, print the message with `%put`, and stop with `%abort cancel`.
- Do not silently substitute defaults for invalid inputs or swallow failures. Check return codes from SAS functions/procedures when failure can occur, and surface `sysmsg()` where appropriate.
- Reuse library helpers such as `%var_exist`, `%var_coexist`, and `%var_attr` when their behavior fits; list them under `Dependency`.

## Processing and cleanup

- Prefer readable DATA/PROC steps and SAS functions over opaque macro-generated code. Quote macro values carefully when they may contain special characters.
- Use predictable WORK intermediates, then remove them with `proc delete` before normal exit. Avoid leaving debug output or temporary datasets behind.
- Preserve the input unless the documented default explicitly permits output to replace it. Keep output ordering and existing values intentional and documented.
- For grouped processing, explicitly sort by the complete BY key before using BY-group processing. Do not concatenate separately filtered subsets and assume they remain interleaved or sorted together.
- Document domain assumptions and edge cases, especially uniqueness requirements, missing-value conventions, and behavior for incomplete ISO8601 values.

## Example outline

```sas
/*
*Brief      : Describe the macro
*Param(Req) : (DATA=)  Input dataset
*Param(Opt) : (OUT=&DATA.)  Output dataset
*Dependency : %var_exist
*Version    : SAS 9.4M7
*History    : YYYY-MM-DD, Author, Original version
*/
%macro example(data=,out=&data.);
%local errtext;

/*1. Exception capture and handling*/
%if %quote(&data.)=%str() %then %let errtext=ERROR: Parameter DATA= not specified.;
%else %if %sysfunc(exist(%qscan(&data.,1,())))=0 %then %let errtext=ERROR: Dataset %quote(&data.) not exist.;
%exception:
%if %bquote(&errtext.)^=%str() %then %do;
  %put &errtext.;
  %abort cancel;
%end;

/*2. Core processing*/
/* Process validated input. */
%mend;
```

This is a structural example, not a requirement to copy its validation literally; adapt checks and output handling to the macro's actual interface.
