#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

perl -e 'open IN, "</usr/share/dict/words";rand($.) < 1 && ($n=$_) while <IN>;print $n' | { read NEW_WORD; sed -i '' -e "s/\(<body>\).*\(<\/body>\)/<body>${NEW_WORD}<\/body>/g" "${SCRIPT_DIR}/../index.html"; }
