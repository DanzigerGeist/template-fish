# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Aleksy Rudy

# `-f` disables file completion. Drop it if your function takes a path operand,
# and add `-a '(__fish_complete_directories)'` if it takes a directory.
complete -c example -f

complete -c example -s u -l upper -d 'Upper-case the text'
complete -c example -s n -l count -x -d 'Print the text N times'
complete -c example -s h -l help -d 'Show help and exit'
