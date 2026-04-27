# syntax=docker/dockerfile:1.7

FROM alpine:3.22

RUN <<EOF
set -eux
apk add --no-cache \
  build-base \
  ca-certificates \
  curl \
  git \
  lua5.1 \
  lua5.1-dev \
  luarocks5.1 \
  neovim \
  trash-cli \
  unzip
if ! command -v trash >/dev/null 2>&1 && command -v trash-put >/dev/null 2>&1; then
  ln -s "$(command -v trash-put)" /usr/local/bin/trash
fi
EOF

WORKDIR /src

COPY nvim-sidebar-dev-1-1.rockspec ./

RUN luarocks-5.1 --tree .luarocks make --only-deps nvim-sidebar-dev-1-1.rockspec

COPY . .

RUN chmod +x run-tests.sh

RUN <<EOF
set -eux
nvim --version | head -n 1
lua5.1 -v
luarocks-5.1 --version
command -v trash
./run-tests.sh
EOF

CMD ["./run-tests.sh"]
