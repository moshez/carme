FROM debian:stretch

ENV VIRTUALENV_HOME=/opt/carme/virtualenvs \
    PYENV_ROOT=/opt/carme/pyenv \
    NCOLONY_ROOT=/opt/carme/ncolony \
    NVM_DIR=/opt/pybay/webaz/nvm

RUN apt-get update
RUN apt-get install -y  \
    make build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev \
    libncursesw5-dev xz-utils tk-dev libffi-dev git apt-transport-https

RUN \
  export \
    PROJECT=pyenv/pyenv-installer \
    SITE=https://github.com \
    WPATH=bin/pyenv-installer  && \
  curl -L $SITE/$PROJECT/raw/master/$WPATH \
  | bash

RUN $PYENV_ROOT/bin/pyenv install 3.7.0

RUN $PYENV_ROOT/bin/pyenv global 3.7.0

RUN $($PYENV_ROOT/bin/pyenv which python3) -m venv \
     /opt/carme/jupyter

RUN /opt/carme/jupyter/bin/pip install jupyterlab ncolony xonsh

RUN mkdir -p $NCOLONY_ROOT/messages $NCOLONY_ROOT/config

RUN /opt/carme/jupyter/bin/python -m ncolony ctl \
    --messages $NCOLONY_ROOT/messages \
    --config $NCOLONY_ROOT/config \
    add jupyter --cmd /opt/carme/jupyter/bin/jupyter \
    --arg lab --arg='--ip=0.0.0.0' --arg=--allow-root \
    --env-inherit HOME

RUN echo '#!/bin/sh' > /opt/carme/entrypoint.sh
RUN echo 'exec /opt/carme/jupyter/bin/python -m twisted \
               ncolony \
               --messages $NCOLONY_ROOT/messages/ \
               --config $NCOLONY_ROOT/config/' >> /opt/carme/entrypoint.sh
RUN chmod +x /opt/carme/entrypoint.sh
COPY add-venv /opt/carme/

#RUN export NVM_DIR=/opt/pybay/webaz/nvm && \
#    mkdir $NVM_DIR && \
#    curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash && \
#    . $NVM_DIR/nvm.sh && \
#    nvm install node && \
#    npm install -g yarn && \
#    cd /opt/pybay/webaz && yarn install

FROM debian:stretch

ENV VIRTUALENV_HOME=/opt/carme/virtualenvs \
    PYENV_ROOT=/opt/carme/pyenv \
    NCOLONY_ROOT=/opt/carme/ncolony \
    NVM_DIR=/opt/carme/webaz/nvm \
    HOME=/opt/carme

COPY --from=0 /opt/carme /opt/carme/

RUN \
  apt-get update && \
  apt-get install -y  libffi6 libsqlite3-0 libssl1.1 git

ENTRYPOINT ["/opt/carme/entrypoint.sh"]
