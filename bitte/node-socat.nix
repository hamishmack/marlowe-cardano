{ writeShellScriptBin, wait-for-socket, socat, lib, coreutils }:

writeShellScriptBin "node-socat" ''
  set -eEuo pipefail

  export PATH=${lib.makeBinPath [ wait-for-socket socat coreutils ]}

  wait-for-socket ''${NOMAD_ALLOC_DIR}/node.sock

  exec socat TCP-LISTEN:bind=''${NOMAD_ADDR_node_socat} UNIX-CONNECT:''${NOMAD_ALLOC_DIR}/node.sock
''
