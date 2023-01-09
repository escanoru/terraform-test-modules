#!/bin/bash

cat > index.html <<EOF
<h1>${server_text}</h1>
<p>DB address        = ${db_address}</p>
<p>DB port           = ${db_port}</p>
<p>DB engine         = ${db_engine}</p>
<p>DB engine version = ${db_engine_version}</p>
EOF

nohup busybox httpd -f -p ${server_port} &
