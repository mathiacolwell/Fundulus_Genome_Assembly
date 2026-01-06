## Kings Creek *Fundulus heteroclitus* Southern Haplotype Genome Assembly 
This repository contains code for the assembly, annotation, and light downstream analyses of the *Fundulus heteroclitus* southern haplotype (Kigns Creek) genome using Oxford Nanopore logn read sequencing. A detailed downstream applciation for methyaltion and variant calling can be found at: https://github.com/mathiacolwell/Epigenetic_plasticity_PAH_tolerance_killifish

Our genome was developed to support studies using the Kings Creek Southern Haplotype *Fundulus heteroclitus* population (BioProject: PRJNA1381666; Accession no: UNDER REVIEW).

This repository assumes familiarity with commandline genomics tools and access to computational resources.

 ## Sequencing Overview
 **Species:** _Fundulus heteroclitus_
 
 **Population:** Kings Creek (Southern haplotype)
 
 **Sequencing Platform:** Oxford Nanopore Technologies
 
 **Annotation:** Liftoff based annotaiton using the MU_UCD_Fhet_4.1 genome (GCF_011125445.2: https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_011125445.2/)
 
 **Date Sequenced:** September 2022

 | Assembly                              | Size (bp)     | Contigs | N50 (bp)   | L50 (num) | Gaps (num) | GC (%) | BUSCO Single (%) | BUSCO Duplicate (%) | BUSCO Fragment (%) | BUSCO Missing (%) |
| ------------------------------------- | ------------- | ------- | ---------- | --------- | ---------- | ------ | ---------------- | ------------------- | ------------------ | ----------------- |
| *Fundulus heteroclitus* (Kings Creek) | 1,067,743,975 | 2,656   | 37,363,536 | 14        | 9,103      | 40.71  | 98.02            | 0.41                | 0.53               | 1.04              |

## Key Features 
- Long-read genome assembyl and polishing workflow
- Structural refinement and gap closing
- Genome annotation and post-assembly quality control
- Stepwise pipeline design

## Tech Stack 
- **Launguages:** Bash, Python
- **Assembly & Polishing:** Flye, Medaka, PurgeDups, RagTag, TGS-GapCloser
- **Annotation:** Liftoff

## Repository Structure
```text
Fundulus_Genome_Assembly/
├── assembly/          # Genome assembly and polishing steps
├── annotation/        # Genome annotation workflows
├── qc/                # Quality control and evaluation outputs
├── scripts/           # Custom helper and summary scripts
├── data/              # Input data references (not tracked)
└── README.md
```
## Design Decisions
- **Modularity:** Major proccessing step is separated to allow reuse or substitution of tools
- **Reproducibility:** logic is scripted, version is controlled
- **Scalability:** Designed to run on workstation environments with minimal modification

## Limitations
- Raw sequencing is not included
- Environment management is assumed by user
- Workflow is script based

## Future Improvements
- Refactor workflow into Snakemake based pipeline
- Add conda environment specs per step
- Include automated summary reports

## Author
**Mathia L. Colwell, PhD**

Postdoctoral Researcher, Oregon Health and Science University

Computational Genomics | Genome Assembly | Epigenomics 
