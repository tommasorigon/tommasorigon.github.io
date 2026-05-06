# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal academic website for Tommaso Rigon (Associate Professor, Università di Milano-Bicocca), built with **Quarto** and hosted on GitHub Pages from the `docs/` output directory.

## Build commands

```bash
# Full project render (preferred — always coherent)
quarto render

# Preview with live reload
quarto preview

# Single file (use sparingly — can fail if freeze cache is stale)
quarto render index.qmd
# If that fails: rm -rf .quarto/_freeze/index && quarto render index.qmd
```

The output directory is `docs/`. Never delete it manually; doing so breaks the rename step in incremental builds.

## Project structure

**Source pages** (root `.qmd` files → compiled to `docs/`):
- `index.qmd` — home, bio, news/awards
- `papers.qmd` — full publication list
- `bio.qmd` — academic positions and education
- `teaching.qmd` — courses and seminar slides
- `tesi.qmd` — thesis info and past students (Italian)
- `post.qmd` — auto-listing of blog posts (reads `post/` directory)

**Blog posts** (`post/<name>/`): each subdirectory is a self-contained post. Seminar/talk posts use a dual-format pattern: one `.qmd` produces both an HTML notebook and a RevealJS slide deck via:
```yaml
format:
  html:
    ...
  revealjs:
    output-file: <name>_slides.html
```
These posts also include `biblio.bib` and an `img/` folder.

**Static assets:**
- `files/cv_Rigon.pdf` + `files/cv_Rigon.tex` — CV (LaTeX source included)
- `files/papers/` — thesis PDFs of past students
- `files/slides/` — older seminar slide PDFs
- `files/template_tesi.zip` + `files/template_tesi/` — LaTeX thesis template for students
- `fonts/` — Latin Modern web fonts (LM Roman, LM Mono, LM Sans)
- `images/` — profile photo and logos

## Configuration

`_quarto.yml` defines:
- Output dir: `docs/`
- `execute: freeze: auto` — R code only re-runs when the source `.qmd` changes; results cached in `.quarto/_freeze/` (this directory should be committed to git)
- HTML theme: `simplex` + `template.css` (custom CSS with `.blue`, `.orange`, `.darkred` span classes used throughout)
- RevealJS slides: logo `images/logoB.png`, footer linking to homepage
- Lua filter `remove-pause.lua` applied globally (strips `{.pause}` from slides)
- Math: KaTeX

## Formatting conventions

- Author name styling: `[Name]{.blue}` or `[Name]{.orange}` for collaborators
- Citations in `papers.qmd`: ordered lists under category headers (`[Preprints]{.blue}`, `[Articles in refereed journals]{.blue}`, etc.)
- Dunson's name is always formatted as `Dunson D. B.` (with space between initials)
- Section headings use `{.central}` class: `## Section title {.central}`
- Comments in `.qmd` files use standard HTML `<!-- -->` to hide outdated content rather than deleting it
