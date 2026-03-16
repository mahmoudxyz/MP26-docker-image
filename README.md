# MP26 · Molecular Phylogenetics

A complete, ready-to-run Docker environment for the MP26 Molecular Phylogenetics course. Everything is pre-installed — R packages, bioinformatics CLI tools, and the full course repository. No setup, no compilation, no dependency issues. Pull the image and start working in under a minute.

---

## Requirements

- [Docker](https://docs.docker.com/get-docker/) (any platform — Linux, macOS, Windows)

---

## Quick start

```bash
docker run -d -p 80:80 -p 8787:8787 -p 8080:8080 \
  -e PASSWORD=phylo123 --name mp26 \
  mahmoudxyz/mp26-phylo
```

Open **http://localhost** in your browser. That's it.

---

## What's inside

### Course data
The full [MP26 GitHub repository](https://github.com/for-giobbe/MP26) is pre-cloned at `~/MP26`, including all example alignments, trees, sequences, and practical data.

### Browser tools

| URL | Tool | Purpose | Login |
|-----|------|---------|-------|
| http://localhost | Hub | Overview, instructions, git pull | — |
| http://localhost:8787 | RStudio | R practicals | `rstudio` / `phylo123` |
| http://localhost:8080 | File browser | Browse, upload, download files | — |

### R packages

| Package | Source |
|---------|--------|
| Biostrings | Bioconductor |
| msa | Bioconductor |
| apex | Bioconductor |
| ape | CRAN |
| seqinr | CRAN |
| phangorn | CRAN |
| phytools | CRAN |
| geiger | CRAN |

### CLI tools

| Tool | Purpose |
|------|---------|
| mafft | Multiple sequence alignment |
| gblocks | Alignment filtering |
| iqtree / iqtree2 | Maximum likelihood phylogenetics |
| paml / codeml | Selection analysis (dN/dS) |
| astral | Coalescent-based species tree |
| orthofinder | Orthology inference |
| phylobayes / pb_mpi | Bayesian phylogenetic inference |
| prank | Codon-aware alignment |
| amas | Alignment concatenation |
| ete3 | Python tree toolkit |

### Pretty output tools

| Tool | Use |
|------|-----|
| `bat` | Syntax-highlighted file viewer (`cat` replacement) |
| `eza` | Modern directory listing (`ls` replacement) |
| `mlr` | TSV/CSV/JSON swiss army knife |
| `csvkit` | `csvlook`, `csvstat`, `csvcut` for tabular data |
| `column` | Simple TSV/CSV pretty-printing |

---

## Terminal access

Open your system terminal and run:

```bash
docker exec -it mp26 bash
```

You land directly in `~/MP26` with all tools on PATH and these aliases ready:

```bash
tsv file.tsv     # pretty-print any TSV file
csv file.csv     # pretty-print any CSV file
bat file.txt     # syntax-highlighted file view
ll               # detailed directory listing
```

---

## Mount your own files

To bring local files into the container:

```bash
docker run -d -p 80:80 -p 8787:8787 -p 8080:8080 \
  -e PASSWORD=phylo123 --name mp26 \
  -v ~/mydata:/home/rstudio/mydata \
  mahmoudxyz/mp26-phylo
```

Your files appear at `~/mydata` inside RStudio, the terminal, and the file browser.

---

## Update course materials

From the hub, click **git pull**. Or from the terminal:

```bash
docker exec mp26 update_repo.sh
```

---

## Stop / restart

```bash
docker stop mp26     # stop the container
docker start mp26    # restart it (all data preserved)
docker rm -f mp26    # remove it completely
```

## Change the password

Pass a different value to `-e PASSWORD`:

```bash
docker run ... -e PASSWORD=mypassword ... mahmoudxyz/mp26-phylo
```

---

## Rebuilding from source

```bash
git clone https://github.com/mahmoudxyz/mp26-phylo-docker
cd mp26-phylo-docker
docker build -t mahmoudxyz/mp26-phylo .
```

---

## Course

[MP26 — Molecular Phylogenetics](https://for-giobbe.github.io/MP26/)
Course material by Giobbe Forni et al. · Docker image by [mahmoudxyz](https://hub.docker.com/r/mahmoudxyz/mp26-phylo)
