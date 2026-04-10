FROM rocker/rstudio:4.3.3

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/envs/MP26_env/bin:/opt/conda/bin:$PATH"

# ── System dependencies ────────────────────────────────────────────────────────
# FIX: added libglpk40 (needed by igraph -> phangorn), libxml2-dev, libcurl4-openssl-dev,
# libssl-dev (needed by many R packages), and the font/image libs needed by
# phytools' plotting dependencies (systemfonts, textshaping, ragg, magick).
# libgdal/libgeos/libproj are added because phytools soft-depends on sf for some
# biogeographic functions and the install fails halfway through without them.
RUN apt-get update && apt-get install -y \
    wget curl git nginx util-linux \
    mpi-default-bin mpi-default-dev \
    python3-pip bat miller \
    libglpk40 libglpk-dev \
    libxml2-dev libcurl4-openssl-dev libssl-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev \
    libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev \
    libmagick++-dev \
    libgdal-dev libgeos-dev libproj-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/batcat /usr/local/bin/bat

# ── eza ───────────────────────────────────────────────────────────────────────
RUN wget -q https://github.com/eza-community/eza/releases/download/v0.18.0/eza_x86_64-unknown-linux-gnu.tar.gz \
    -O /tmp/eza.tar.gz && \
    tar -xzf /tmp/eza.tar.gz -C /usr/local/bin && \
    rm /tmp/eza.tar.gz

# ── csvkit ────────────────────────────────────────────────────────────────────
RUN pip3 install csvkit --break-system-packages 2>/dev/null || pip3 install csvkit

# ── tsv and csv as real scripts (aliases don't work in non-interactive shells) ─
RUN printf '#!/bin/bash\nmlr --itsv --opprint --allow-ragged-csv-input cat "$@"\n' \
    > /usr/local/bin/tsv && chmod +x /usr/local/bin/tsv && \
    printf '#!/bin/bash\nmlr --icsv --opprint --allow-ragged-csv-input cat "$@"\n' \
    > /usr/local/bin/csv && chmod +x /usr/local/bin/csv && \
    printf '#!/bin/bash\neza -la "$@"\n' \
    > /usr/local/bin/ll && chmod +x /usr/local/bin/ll

# ── Filebrowser ───────────────────────────────────────────────────────────────
RUN wget -q https://github.com/filebrowser/filebrowser/releases/download/v2.27.0/linux-amd64-filebrowser.tar.gz \
    -O /tmp/fb.tar.gz && \
    tar -xzf /tmp/fb.tar.gz -C /usr/local/bin filebrowser && \
    rm /tmp/fb.tar.gz && chmod +x /usr/local/bin/filebrowser

# ── Miniforge ─────────────────────────────────────────────────────────────────
RUN wget -q https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh \
    -O /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p /opt/conda && \
    rm /tmp/miniforge.sh && \
    /opt/conda/bin/conda install -n base -c conda-forge mamba -y && \
    /opt/conda/bin/conda clean -afy

# ── Bioinformatics tools ───────────────────────────────────────────────────────
RUN /opt/conda/bin/mamba create -y -n MP26_env python=3.10 \
    -c bioconda -c conda-forge \
    mafft gblocks iqtree paml astral-tree \
    orthofinder prank amas ete3 \
    && /opt/conda/bin/conda clean -afy

RUN ln -s /opt/conda/envs/MP26_env/bin/iqtree \
         /opt/conda/envs/MP26_env/bin/iqtree2

RUN /opt/conda/bin/mamba install -y -n MP26_env \
    -c bioconda phylobayes-mpi \
    && /opt/conda/bin/conda clean -afy

# ── R packages ─────────────────────────────────────────────────────────────────
# FIX: split into separate steps and use stop(...) so a single failed package
# fails the Docker build instead of being silently ignored. This is why
# phytools was missing in the previous image — one of its deps failed quietly
# during build and install.packages() just moved on.
#
# Also: install phytools BEFORE the verification step so any missing system
# lib surfaces loudly here rather than at first-use by a student.
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org'); \
          if (!requireNamespace('BiocManager', quietly=TRUE)) stop('BiocManager install failed')"

RUN R -e "BiocManager::install(c('Biostrings','msa','apex'), ask=FALSE, update=FALSE); \
          for (p in c('Biostrings','msa','apex')) \
            if (!requireNamespace(p, quietly=TRUE)) stop(paste('Bioconductor package', p, 'failed to install'))"

RUN R -e "install.packages(c('ape','seqinr','phangorn','phytools','geiger'), \
                           repos='https://cloud.r-project.org', \
                           Ncpus=parallel::detectCores()); \
          for (p in c('ape','seqinr','phangorn','phytools','geiger')) \
            if (!requireNamespace(p, quietly=TRUE)) stop(paste('CRAN package', p, 'failed to install'))"

# FIX: final sanity check — actually load every required package. If any of
# them has a broken shared library (like phangorn needing libglpk), this will
# fail the build here instead of at first student use.
RUN R -e "pkgs <- c('BiocManager','Biostrings','msa','apex','ape','seqinr','phangorn','phytools','geiger'); \
          for (p in pkgs) { \
            message('Loading ', p); \
            library(p, character.only=TRUE); \
          }; \
          message('All R packages load cleanly.')"

# ── Clone course repo ──────────────────────────────────────────────────────────
RUN git clone https://github.com/for-giobbe/MP26.git /home/rstudio/MP26 && \
    chown -R rstudio:rstudio /home/rstudio/MP26 && \
    chmod -R g+w /home/rstudio/MP26 && \
    git config --global --add safe.directory /home/rstudio/MP26 && \
    sudo -u rstudio git config --global --add safe.directory /home/rstudio/MP26

# ── PATH for all shells via /etc/environment ──────────────────────────────────
RUN echo 'PATH="/opt/conda/envs/MP26_env/bin:/opt/conda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"' \
    >> /etc/environment

# ── Shell welcome & cd for interactive shells ─────────────────────────────────
RUN printf '%s\n' \
    'export PATH="/opt/conda/envs/MP26_env/bin:/opt/conda/bin:$PATH"' \
    'cd /home/rstudio/MP26' \
    'echo ""' \
    'echo "  MP26 · Molecular Phylogenetics"' \
    'echo "  mafft | iqtree | iqtree2 | paml | astral | orthofinder | phylobayes | prank | amas"' \
    'echo "  tsv <file> | csv <file> | bat <file> | ll"' \
    'echo ""' \
    > /etc/profile.d/mp26.sh && chmod +x /etc/profile.d/mp26.sh && \
    echo 'source /etc/profile.d/mp26.sh' >> /home/rstudio/.bashrc && \
    echo 'source /etc/profile.d/mp26.sh' >> /root/.bashrc

# ── R opens in MP26 ───────────────────────────────────────────────────────────
RUN echo 'setwd("~/MP26")' > /home/rstudio/.Rprofile && \
    chown rstudio:rstudio /home/rstudio/.Rprofile

# ── s6 services ───────────────────────────────────────────────────────────────
COPY s6/nginx/run        /etc/services.d/nginx/run
COPY s6/filebrowser/run  /etc/services.d/filebrowser/run
COPY s6/update-api/run   /etc/services.d/update-api/run

RUN chmod +x /etc/services.d/nginx/run \
             /etc/services.d/filebrowser/run \
             /etc/services.d/update-api/run

# ── Static & config files ─────────────────────────────────────────────────────
COPY nginx.conf       /etc/nginx/nginx.conf
COPY update_api.py    /usr/local/bin/update_api.py
COPY update_repo.sh   /usr/local/bin/update_repo.sh
COPY index.html       /var/www/html/index.html

RUN chmod +x /usr/local/bin/update_repo.sh && \
    mkdir -p /var/log/nginx

EXPOSE 80 8787 8080

CMD ["/init"]