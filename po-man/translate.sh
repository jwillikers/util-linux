#!/usr/bin/env bash
set -eou pipefail

function usage()
{
    cat << HEREDOC

 Usage: $PROGRAM --srcdir <srcdir> --destdir <destdir> --asciidoctor-load-path <directory> --docdir <docdir> --po4acfg <file> --util-linux-version <version> [<locale>...]

 Options:
  --help                               show this help message and exit
  --srcdir <srcdir>                    directory containing the asciidoc files to translate
  --destdir <destdir>                  directory in which to place the translated asciidoc files and man pages
  --asciidoctor-load-path <directory>  value for the --load-path option passed to the asciidoctor command
  --docdir <docdir>                    directory where the package documentation will be installed
  --util-linux-version <version>       version of util-linux to include in the man pages
  --po4acfg <file>                     path to the po4a.cfg file

HEREDOC
}

MANADOCS=()
PROGRAM=$(basename "$0")

while [[ $# -gt 0 ]]; do
  case $1 in
    --srcdir)
      SRCDIR="$2"
      shift
      shift
      ;;
    --destdir)
      DESTDIR="$2"
      shift
      shift
      ;;
    --asciidoctor-load-path)
      ASCIIDOCTOR_LOAD_PATH="$2"
      shift
      shift
      ;;
    --docdir)
      DOCDIR="$2"
      shift
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    --po4acfg)
      PO4ACFG="$2"
      shift
      shift
      ;;
    --util-linux-version)
      VERSION="$2"
      shift
      shift
      ;;
    --*|-*)
      echo "Unknown option $1"
      usage
      exit 1
      ;;
    *)
      MANADOCS+=("$1")
      shift
      ;;
  esac
done

set -- "${MANADOCS[@]}"

mapfile -t LOCALES < <( awk '/\[po4a_langs\]/ {for (i=2; i<=NF; i++) print $i}' "$PO4ACFG" )

mkdir --parents "$DESTDIR"

DESTDIR=$( OLDPWD=- CDPATH='' cd -P -- "$DESTDIR" && pwd )

# po4a --srcdir "$SRCDIR" --destdir "$DESTDIR" --no-translations --verbose "$PO4ACFG"
po4a --srcdir "$SRCDIR" --destdir "$DESTDIR" "$PO4ACFG"

for LOCALE in "${LOCALES[@]}"; do
    LOCALE_ADOC_DIR="$DESTDIR/$LOCALE"
    # for MANADOC in "${MANADOC[@]}"; do
    #   MANADOC_NAME=$(basename "$MANADOC")
    #   po4a --srcdir "$SRCDIR" --destdir "$DESTDIR" --translate-only "$LOCALE/$MANADOC_NAME" "$PO4ACFG"
    # done
    ADOCS=$(shopt -s nullglob dotglob; echo "$LOCALE_ADOC_DIR"/*.adoc)
    for ADOC in $ADOCS; do
        PAGE="${ADOC%.*}"
        SECTION="${PAGE##*.}"
        asciidoctor \
            --backend manpage \
            --attribute VERSION="$VERSION" \
            --attribute release-version="$VERSION" \
            --attribute ADJTIME_PATH=/etc/adjtime \
            --attribute package-docdir="$DOCDIR" \
            --base-dir "$LOCALE_ADOC_DIR" \
            --destination-dir "$DESTDIR/man/$LOCALE/man$SECTION" \
            --load-path "$ASCIIDOCTOR_LOAD_PATH" \
            --require asciidoctor-includetracker \
            "$ADOC"
    done
done
