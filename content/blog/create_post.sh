#! /bin/bash
TITLE=$1
PATH=./
DATE=$(/bin/date +%F)

exit_if_fail() {
  echo "Execute command: ($@)"
  ($@)
  RET=$?
  if [ "$RET" -ne 0 ]; then
    echo "Error occur during execute command ($@)"
    exit $RET
  fi
}

create_post_dir() {
  /bin/mkdir -p $PATH/${TITLE}
}

create_template_file() {
  POST_PATH=$PATH/${TITLE}
  /usr/bin/touch ${POST_PATH}/index.md
  /bin/cat > ${POST_PATH}/index.md << EOF
---
title: ${TITLE}
date: ${DATE}
description:
---
EOF
}

exit_if_fail create_post_dir
exit_if_fail create_template_file