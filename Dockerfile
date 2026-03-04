FROM mambaorg/micromamba:latest AS builder

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    CONDA_ENV_PATH=/opt/conda-env

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        build-essential \
        gfortran \
        libgeos-dev \
        libgomp1 \
        libproj-dev \
        proj-bin \
        proj-data \
    && rm -rf /var/lib/apt/lists/*

RUN micromamba create -y -p "${CONDA_ENV_PATH}" -c conda-forge \
        "python=3.10" \
        pip \
        esmpy \
    && micromamba run -p "${CONDA_ENV_PATH}" python -m pip install --upgrade pip setuptools wheel \
    && micromamba run -p "${CONDA_ENV_PATH}" python -m pip install --prefer-binary \
        "Pillow<12" \
        "cartopy<0.25" \
        "loguru<0.8" \
        "matplotlib<3.10" \
        "metpy<1.7" \
        "netCDF4<1.8" \
        "numpy<2" \
        "pandas<2.3" \
        "psycopg2-binary<2.10" \
        "pykdtree<1.5" \
        "pyshp<2.4" \
        "scipy<1.15" \
        "xarray<2025.0" \
        "xesmf==0.8.10" \
        cinrad_data \
        vanadis \
    && micromamba clean --all --yes

FROM mambaorg/micromamba:latest

USER root

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MPLBACKEND=Agg \
    MPLCONFIGDIR=/tmp/matplotlib \
    XDG_CACHE_HOME=/tmp/.cache \
    CONDA_ENV_PATH=/opt/conda-env \
    CONDA_PREFIX=/opt/conda-env \
    ESMFMKFILE=/opt/conda-env/lib/esmf.mk \
    PATH=/opt/conda-env/bin:/usr/local/bin:/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        libgeos-c1v5 \
        libgomp1 \
        libproj25 \
        proj-bin \
        proj-data \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/conda-env /opt/conda-env
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN /opt/conda-env/bin/python -c 'import os, xesmf, esmpy; assert os.path.exists(os.environ["ESMFMKFILE"])'

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /logs /opt/python-3.10.13/bin /opt/conda/bin /opt/conda/condabin \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/conda-env/bin/python "$@"' > /opt/python-3.10.13/bin/python \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/conda-env/bin/pip "$@"' > /opt/python-3.10.13/bin/pip \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/conda-env/bin/python "$@"' > /opt/conda/bin/python \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/conda-env/bin/python "$@"' > /opt/conda/bin/python3 \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/conda-env/bin/pip "$@"' > /opt/conda/bin/pip \
    && chmod +x \
        /opt/python-3.10.13/bin/python \
        /opt/python-3.10.13/bin/pip \
        /opt/conda/bin/python \
        /opt/conda/bin/python3 \
        /opt/conda/bin/pip

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
