#!/bin/bash
set -e

perl -e 'open IN, "</usr/share/dict/words";rand($.) < 1 && ($n=$_) while <IN>;print $n' | { read test; sed -i '' -e "s/\(<body>\).*\(<\/body>\)/<body>$test<\/body>/g" index.html; }
