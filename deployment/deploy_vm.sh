#!/bin/bash

rm /tmp/icky_venus.tar.gz
tar --exclude-from='deployment/exclude.txt' --no-xattrs -czvf /tmp/icky_venus.tar.gz . && \
scp /tmp/icky_venus.tar.gz root@digital-ocean:/tmp && \
ssh digital-ocean << EOF
rm -rf ~/sites/icky_venus/
mkdir -p ~/sites/icky_venus/
tar -xzvf /tmp/icky_venus.tar.gz -C ~/sites/icky_venus && \
rm /tmp/icky_venus.tar.gz && \
cd ~/sites/icky_venus/ && \
asdf local elixir 1.16 && \
mix deps.get && \
MIX_ENV=prod mix release --overwrite && \
~/sites/icky_venus/_build/prod/rel/icky_venus/bin/icky_venus daemon && \
~/sites/icky_venus/_build/prod/rel/icky_venus/bin/icky_venus restart
EOF

# need to target x86 and linux
# MIX_ENV=prod mix release --overwrite && \
# tar -czvf /tmp/icky_venus.tar.gz _build/prod/rel/icky_venus/ && \
# scp /tmp/icky_venus.tar.gz root@digital-ocean:/tmp && \
# ssh digital-ocean << EOF
# rm -rf ~/sites/icky_venus/
# mkdir -p ~/sites/icky_venus/
# tar -xzvf /tmp/icky_venus.tar.gz -C ~/sites/icky_venus && \
# rm /tmp/icky_venus.tar.gz && \
# ~/sites/icky_venus/_build/prod/rel/icky_venus/bin/icky_venus daemon
# ~/sites/icky_venus/_build/prod/rel/icky_venus/bin/icky_venus restart
# EOF
