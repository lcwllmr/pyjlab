FROM python:3.13-bookworm

# installation and config
RUN pip install --no-cache-dir --upgrade pip && \
  pip install --no-cache-dir \
    jupyterlab jupyterlab-vim jupyterlab-lsp \
    python-lsp-server
RUN jupyter labextension disable "@jupyterlab/apputils-extension:announcements"
COPY ./config/overrides.json /usr/local/share/jupyter/lab/settings/
COPY ./config/plugin.jupyterlab-settings /root/.jupyter/lab/user-settings/@jupyterlab/extensionmanager-extension/

# install some userspace packages
RUN pip install --no-cache-dir numpy scipy matplotlib pandas sympy

# entrypoint
RUN mkdir /workspace
WORKDIR /workspace
VOLUME ["/workspace"]
EXPOSE 8888
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", \
  "--no-browser", "--allow-root", \
  "--NotebookApp.token=", "--NotebookApp.password=", \
  "--notebook-dir=/workspace"]
