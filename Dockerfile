FROM python:3.10-slim-bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    VENV_PATH=/opt/venv

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

RUN python -m venv "${VENV_PATH}"

ENV PATH="${VENV_PATH}/bin:${PATH}"

RUN pip install --upgrade pip setuptools wheel \
    && pip install --prefer-binary \
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
        cinrad_data \
        vanadis

ENV ESMPY_PATH=/opt/esmpy \
    ESMPY_BRIDGE_PATH=/opt/esmpy-bridge

COPY --from=mambaorg/micromamba:latest /usr/bin/micromamba /usr/local/bin/micromamba

RUN micromamba create -y -p "${ESMPY_PATH}" -c conda-forge \
        "python=3.10" \
        esmpy \
    && pip install --prefer-binary "xesmf==0.8.10" \
    && mkdir -p "${ESMPY_BRIDGE_PATH}" \
    && for name in esmpy ESMF ESMF.py; do \
        if [ -e "${ESMPY_PATH}/lib/python3.10/site-packages/${name}" ]; then \
            cp -a "${ESMPY_PATH}/lib/python3.10/site-packages/${name}" "${ESMPY_BRIDGE_PATH}/"; \
        fi; \
    done \
    && if [ ! -e "${ESMPY_BRIDGE_PATH}/esmpy" ] \
        && [ ! -e "${ESMPY_BRIDGE_PATH}/ESMF" ] \
        && [ ! -e "${ESMPY_BRIDGE_PATH}/ESMF.py" ]; then \
        echo "esmpy bridge package not found" >&2; exit 1; \
    fi \
    && micromamba clean --all --yes

FROM python:3.10-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MPLBACKEND=Agg \
    MPLCONFIGDIR=/tmp/matplotlib \
    XDG_CACHE_HOME=/tmp/.cache \
    PYTHONPATH=/opt/esmpy-bridge \
    LD_LIBRARY_PATH=/opt/esmpy/lib \
    VENV_PATH=/opt/venv \
    PATH=/opt/venv/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        bash \
        libgeos-c1v5 \
        libgomp1 \
        libproj25 \
        proj-bin \
        proj-data \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv
COPY --from=builder /opt/esmpy /opt/esmpy
COPY --from=builder /opt/esmpy-bridge /opt/esmpy-bridge
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && mkdir -p /logs /opt/python-3.10.13/bin /opt/conda/bin /opt/conda/condabin \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/venv/bin/python "$@"' > /opt/python-3.10.13/bin/python \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/venv/bin/pip "$@"' > /opt/python-3.10.13/bin/pip \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/venv/bin/python "$@"' > /opt/conda/bin/python \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/venv/bin/python "$@"' > /opt/conda/bin/python3 \
    && printf '%s\n' '#!/bin/sh' 'exec /opt/venv/bin/pip "$@"' > /opt/conda/bin/pip \
    && chmod +x \
        /opt/python-3.10.13/bin/python \
        /opt/python-3.10.13/bin/pip \
        /opt/conda/bin/python \
        /opt/conda/bin/python3 \
        /opt/conda/bin/pip

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
