# Needed variables:
#   NODE_STATE_DIR
#   NOMAD_ALLOC_DIR # node socket stored in $NOMAD_ALLOC_DIR/node.sock
#   NOMAD_PORT_node
{ writeShellScriptBin, cardano-node, coreutils, lib, curl, gzip, gnutar }:
let
  config-dir = ./config;
in
writeShellScriptBin "entrypoint" ''
  set -eEuo pipefail

  export PATH="${lib.makeBinPath [ coreutils cardano-node curl gzip gnutar ]}"

  export SSL_CERT_FILE="/etc/ssl/certs/ca-bundle.crt"

  rm -fR "$NODE_STATE_DIR/db"

  curl https://public-chain-db-backups.s3.us-west-2.amazonaws.com/marlowe/node-20220322a.tar.gz | gunzip | tar x

  mv node.db "$NODE_STATE_DIR/db"

  exec cardano-node run --topology ${config-dir}/topology.yaml --database-path "$NODE_STATE_DIR/db" --socket-path "$NOMAD_ALLOC_DIR/node.sock" --config ${config-dir}/config.json  --port "$NOMAD_PORT_node"
''
