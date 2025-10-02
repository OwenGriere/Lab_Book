#!/usr/bin/env bash
set -euo pipefail
# build.sh — compile src/rapport.tex avec nom de sortie personnalisé

JOBNAME="TP_MDCG"
MAIN="rapport.tex"
SRCDIR="src/TP_MDCG"
OUTDIR="PDF"
USE_TOC=1
USE_GLOSSARY=0
USE_BIB=0

cleanup() {
  # Supprime uniquement les fichiers temporaires LaTeX dans $SRCDIR
  ( cd "$SRCDIR" && rm -f \
      *.aux *.log *.out *.toc *.lof *.lot \
      *.fls *.fdb_latexmk *.synctex.gz \
      *.bbl *.bcf *.blg *.run.xml \
      *.acn *.acr *.alg *.glg *.glo *.gls *.ist \
      *.nav *.snm *.vrb *.xdv *.thm 2>/dev/null || true )
}

printf "[BUILD]\n\tDirectoy=${SRCDIR}\n\tOutput_directory=${OUTDIR}\n\tJOBNAME=${JOBNAME}\n"
cd "${SRCDIR}"

# 1ère passe
pdflatex -interaction=nonstopmode -halt-on-error -jobname="${JOBNAME}" "${MAIN}" >/dev/null

# Bibliographie si activée (biber)
if [[ "${USE_BIB}" -eq 1 ]]; then
  if [[ -f "references/references.bib" ]]; then
    if command -v biber >/dev/null 2>&1; then
      biber "${JOBNAME}" >/dev/null
    else
      echo "Avertissement: 'biber' introuvable. Installez-le (ex: sudo apt install biber)."
    fi
  else
    echo "Avertissement: references/references.bib manquant (biber ignoré)."
  fi
fi

# Glossaire si activé
if [[ "${USE_GLOSSARY}" -eq 1 ]]; then
  if command -v makeglossaries >/dev/null 2>&1; then
    makeglossaries "${JOBNAME}" >/dev/null
  else
    echo "Avertissement: 'makeglossaries' introuvable."
  fi
fi

# 2ème passe
pdflatex -interaction=nonstopmode -halt-on-error -jobname="${JOBNAME}" "${MAIN}" >/dev/null

# 3ème passe si sommaire
if [[ "${USE_TOC}" -eq 1 ]]; then
  pdflatex -interaction=nonstopmode -halt-on-error -jobname="${JOBNAME}" "${MAIN}" >/dev/null
fi

echo -e "\tDONE"

cd ../..

if [[ -f "${SRCDIR}/${JOBNAME}.pdf" ]]; then
  mv "${SRCDIR}/${JOBNAME}.pdf" "${OUTDIR}/${JOBNAME}.pdf"
  echo "[INFO] PDF généré: ${OUTDIR}/${JOBNAME}.pdf"
else
  echo "[ERROR] PDF non trouvé"
  exit 1
fi

cleanup

echo "[INFO] Cleanup Latex finished"
