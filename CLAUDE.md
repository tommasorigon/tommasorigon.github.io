# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal academic website for Tommaso Rigon (Associate Professor, Università di Milano-Bicocca), built with **Quarto** and hosted on GitHub Pages from the `docs/` output directory.

## Build commands

```bash
# Render file by file (this is the working workflow)
quarto render index.qmd
quarto render post/<name>/<name>.qmd
# If that fails: rm -rf .quarto/_freeze/index && quarto render index.qmd

# Preview with live reload
quarto preview

# Full project render: works, as long as no format other than html is declared in
# _quarto.yml or in a directory-level _metadata.yml (Quarto 1.7.x bug: that makes the
# render end with a misleading "rename '<file>.html' -> 'docs/.../<file>.html'" NotFound
# and leaves stray .html files and site_libs/ in the root). RevealJS defaults therefore
# live in post/revealjs-defaults.yml, included by each deck via `metadata-files`.
# A failing chunk in any file aborts the run with the same rename error; the real
# error is higher up in the output.
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
- HTML theme: `simplex` + `template.css` (custom CSS with `.blue`, `.orange`, `.darkred` span classes used throughout)
- RevealJS slide defaults (logo `images/logoB.png`, footer linking to homepage, theme) are in `post/revealjs-defaults.yml` (included by each deck with `metadata-files: [../revealjs-defaults.yml]`), NOT in `_quarto.yml` (see build notes)
- Lua filter `remove-pause.lua` applied globally (strips `{.pause}` from slides)
- Math: KaTeX

## Formatting conventions

- Author name styling: `[Name]{.blue}` or `[Name]{.orange}` for collaborators
- Citations in `papers.qmd`: ordered lists under category headers (`[Preprints]{.blue}`, `[Articles in refereed journals]{.blue}`, etc.)
- Dunson's name is always formatted as `Dunson, D. B.` (comma after surname, space between initials)
- Section headings use `{.central}` class: `## Section title {.central}`
- Comments in `.qmd` files use standard HTML `<!-- -->` to hide outdated content rather than deleting it
