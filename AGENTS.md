注意
1. 请勿修改我的py项目代码
2. 请勿将源码打包进镜像中
3. 我容器中不需要工作空间
4. 使用算法镜像的skills 从新验收验证下 Dockerfile
5. 若算法依赖包含 `xesmf`、`esmpy`、`ESMF`，或运行时需要 `esmf.mk`，优先使用单一 `conda`/`micromamba` 环境管理，不要再混用 `python:slim + venv + conda`
6. 若依赖明显带有 `Fortran`、`MPI`、`NetCDF`、`HDF5`、`GEOS`、`PROJ` 等原生库耦合，且 `pip` 安装容易出现 ABI、动态库或环境变量问题，优先考虑 `conda`
7. 遇到以下包时，默认优先判断是否应使用 `conda`：`esmpy`、`xesmf`、`ESMF` 相关组件；以及 `cartopy`、`pyproj`、`netCDF4`、`scipy`、`h5py` 这类强依赖底层系统库的包（尤其是 `arm64` 或多架构构建时）
8. 一旦选择 `conda` 作为主环境，尽量把 Python 依赖统一安装到同一个 `conda` 前缀中，避免再额外叠加 `venv`
9. 使用 `esmpy`/`ESMF` 时，运行时需显式检查并设置 `ESMFMKFILE`
10. 若依赖主要是纯 Python 包，或对应版本已有稳定 wheel，优先继续使用 `pip`，不要无意义引入 `conda`

本次镜像结论
1. 这个项目已验证更适合统一使用 `micromamba/conda` 管理依赖环境
2. `xesmf + esmpy + ESMF` 组合不适合拆桥接，也不适合和独立 `venv` 混用
3. 保持源码通过宿主机挂载运行，镜像仅提供运行环境
