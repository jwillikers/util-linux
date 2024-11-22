#!/usr/bin/env bash
set -eou pipefail

function usage()
{
    cat << HEREDOC

 Usage:
  $PROGRAM --mandir <directory> --mansrcdir <directory> <manpage>...

 Options:
  --help                             show this help message and exit
  --mandir <mandir>                  directory in which to install the man pages, usually share/man
  --mansrcdir <mansrcdir>            directory containing the man pages to install

 Environment Variables:
  MESON_INSTALL_DESTDIR_PREFIX       install destination directory

HEREDOC
}

MANPAGES=()
PROGRAM=$(basename "$0")

while [[ $# -gt 0 ]]; do
  case $1 in
    --help)
      usage
      exit 0
      ;;
    --mandir)
      MANDIR="$2"
      shift
      shift
      ;;
    --mansrcdir)
      MANSRCDIR="$2"
      shift
      shift
      ;;
    --*|-*)
      echo "Unknown option $1"
      usage
      exit 1
      ;;
    *)
      MANPAGES+=("$1")
      shift
      ;;
  esac
done

set -- "${MANPAGES[@]}"

if [ ${#MANPAGES[@]} -eq 0 ]; then
    if [ -z ${MESON_INSTALL_QUIET+x} ]; then
        echo "Warning: no translated man pages selected to install"
    fi
    exit 0
fi

for LOCALEDIR in "$MANSRCDIR"/*/; do
    LOCALE=$(basename "$LOCALEDIR")
    for MANPAGE in "${MANPAGES[@]}"; do
        SECTION="${MANPAGE##*.}"
        PAGE="$LOCALEDIR/man$SECTION/$MANPAGE"
        if [ -f "$PAGE" ]; then
            if [ -z ${MESON_INSTALL_QUIET+x} ]; then
                echo "Installing $PAGE to $MESON_INSTALL_DESTDIR_PREFIX/$MANDIR/$LOCALE/man$SECTION"
            fi
            install -D --mode=0644 --target-directory="$MESON_INSTALL_DESTDIR_PREFIX/$MANDIR/$LOCALE/man$SECTION" "$PAGE"
        fi
    done
done
