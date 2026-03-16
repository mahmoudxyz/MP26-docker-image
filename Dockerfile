FROM rocker/rstudio:4.3.3

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/envs/MP26_env/bin:/opt/conda/bin:$PATH"

# ── System dependencies ────────────────────────────────────────────────────────
RUN apt-get update && apt-get install -y \
    wget curl git nginx util-linux \
    mpi-default-bin mpi-default-dev \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# ── Pretty CLI tools ───────────────────────────────────────────────────────────
# bat  - pretty file viewer with syntax highlighting
# eza  - modern ls replacement
# mlr  - miller: TSV/CSV/JSON swiss army knife
# csvkit - CSV tools: csvlook, csvstat, csvcut, csvsql
RUN apt-get update && apt-get install -y bat && rm -rf /var/lib/apt/lists/* && \
    ln -sf /usr/bin/batcat /usr/local/bin/bat

RUN wget -q https://github.com/eza-community/eza/releases/download/v0.18.0/eza_x86_64-unknown-linux-gnu.tar.gz \
    -O /tmp/eza.tar.gz && \
    tar -xzf /tmp/eza.tar.gz -C /usr/local/bin && \
    rm /tmp/eza.tar.gz

RUN apt-get update && apt-get install -y miller && rm -rf /var/lib/apt/lists/*

RUN pip3 install csvkit --break-system-packages 2>/dev/null || pip3 install csvkit

# ── Filebrowser ───────────────────────────────────────────────────────────────
RUN wget -q https://github.com/filebrowser/filebrowser/releases/download/v2.27.0/linux-amd64-filebrowser.tar.gz \
    -O /tmp/fb.tar.gz && \
    tar -xzf /tmp/fb.tar.gz -C /usr/local/bin filebrowser && \
    rm /tmp/fb.tar.gz && \
    chmod +x /usr/local/bin/filebrowser

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
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org')" && \
    R -e "BiocManager::install(c('Biostrings','msa','apex'), ask=FALSE)" && \
    R -e "install.packages(c('ape','seqinr','phangorn','phytools','geiger'), repos='https://cloud.r-project.org')"

# ── Clone course repo ──────────────────────────────────────────────────────────
RUN git clone https://github.com/for-giobbe/MP26.git /home/rstudio/MP26 && \
    chown -R rstudio:rstudio /home/rstudio/MP26 && \
    git config --global --add safe.directory /home/rstudio/MP26 && \
    sudo -u rstudio git config --global --add safe.directory /home/rstudio/MP26

# ── Shell environment ──────────────────────────────────────────────────────────
RUN echo 'export PATH="/opt/conda/envs/MP26_env/bin:$PATH"' >> /home/rstudio/.bashrc && \
    echo 'alias ls="eza"' >> /home/rstudio/.bashrc && \
    echo 'alias ll="eza -la"' >> /home/rstudio/.bashrc && \
    echo 'alias cat="bat --paging=never"' >> /home/rstudio/.bashrc && \
    echo 'alias tsv="mlr --itsv --opprint --allow-ragged-csv-input --skip-trivial-records cat"' >> /home/rstudio/.bashrc && \
    echo 'alias csv="mlr --icsv --opprint --allow-ragged-csv-input cat"' >> /home/rstudio/.bashrc && \
    echo 'cd ~/MP26' >> /home/rstudio/.bashrc && \
    echo 'echo ""' >> /home/rstudio/.bashrc && \
    echo 'echo "  MP26 · Molecular Phylogenetics"' >> /home/rstudio/.bashrc && \
    echo 'echo "  mafft | iqtree/iqtree2 | paml | astral | orthofinder | phylobayes | prank | amas"' >> /home/rstudio/.bashrc && \
    echo 'echo "  mlr (TSV/CSV) | bat (files) | csvlook (tables) | eza (dirs)"' >> /home/rstudio/.bashrc && \
    echo 'echo ""' >> /home/rstudio/.bashrc && \
    echo 'export PATH="/opt/conda/envs/MP26_env/bin:$PATH"' >> /root/.bashrc && \
    echo 'alias ls="eza"' >> /root/.bashrc && \
    echo 'alias ll="eza -la"' >> /root/.bashrc && \
    echo 'alias cat="bat --paging=never"' >> /root/.bashrc && \
    echo 'alias tsv="mlr --itsv --opprint --allow-ragged-csv-input cat"/.bashrc && \
    echo 'alias csv="mlr --icsv --opprint --allow-ragged-csv-input cat"/.bashrc && \
    echo 'cd /home/rstudio/MP26' >> /root/.bashrc && \
    echo 'echo ""' >> /root/.bashrc && \
    echo 'echo "  MP26 · Molecular Phylogenetics"' >> /root/.bashrc && \
    echo 'echo "  mafft | iqtree/iqtree2 | paml | astral | orthofinder | phylobayes | prank | amas"' >> /root/.bashrc && \
    echo 'echo "  tsv file.tsv | csv file.csv | bat file | ll"' >> /root/.bashrc && \
    echo 'echo ""' >> /root/.bashrc

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