#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------
# latex_generator.sh
# Génère un squelette LaTeX + build.sh à partir d'un
# fichier de base constant: ./rapport_base.tex
# (le script lit ce fichier à l'exécution)
#
# Options: --toc --title --glossary --appendix --bib
# Obligatoire: -d/--dir <dossier>, -o/--output <nom_pdf>
# -----------------------------------------

usage() {
  cat <<'USAGE'
Usage:
  latex_generator.sh -d <dossier_projet> -o <nom_pdf> [--toc] [--title] [--glossary] [--appendix] [--bib] [--force]

Options:
  -d, --dir <dossier>     Dossier projet à créer (ex: Rapport)
  -o, --output <nom_pdf>  Nom du PDF de sortie (sans .pdf), via -jobname (ex: rapport)
      --toc               Ajouter un sommaire (table des matières)
      --title             Ajouter une page de garde
      --glossary          Activer glossaire/acronymes (glossaries + makeglossaries)
      --appendix          Ajouter une section Annexe
      --bib               Activer la bibliographie (BibLaTeX+biber) avec src/references/references.bib
      --force             Ecraser le dossier s'il existe
  -h, --help              Afficher l'aide

Exemples:
  ./latex_generator.sh -d Rapport -o rapport --toc --title
  ./latex_generator.sh -d Memoire_M2 -o Memoire_Final --toc --title --glossary --appendix --bib
USAGE
}

# --- Args
DIR=""; JOBNAME=""
ADD_TOC=0; ADD_TITLE=0; ADD_GLOSSARY=0; ADD_APPENDIX=0; ADD_BIB=0; FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -d|--dir)
      [[ $# -ge 2 ]] || { echo "Manque une valeur pour $1"; exit 1; }
      DIR="$2"; shift 2 ;;
    -o|--output)
      [[ $# -ge 2 ]] || { echo "Manque une valeur pour $1"; exit 1; }
      JOBNAME="$2"; shift 2 ;;
    --toc)       ADD_TOC=1; shift ;;
    --title)     ADD_TITLE=1; shift ;;
    --glossary)  ADD_GLOSSARY=1; shift ;;
    --appendix)  ADD_APPENDIX=1; shift ;;
    --bib)       ADD_BIB=1; shift ;;
    --force)     FORCE=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    *) echo "Option inconnue: $1"; usage; exit 1 ;;
  esac
done

[[ -z "$DIR" || -z "$JOBNAME" ]] && { echo "Erreur: -d et -o sont obligatoires."; usage; exit 1; }

# --- Prépare arborescence
SRC="src/$DIR"; REFS="$SRC/references"; FIG="$SRC/figures"; PDFS="PDF"
[[ -e "$SRC" && $FORCE -eq 0 ]] && { echo "Erreur: '$SRC' existe déjà. Utilise --force pour écraser."; exit 1; }
rm -rf "$SRC"; mkdir -p "$SRC" "$REFS" "$FIG" 

printf "\n[BUILD] Projet LaTeX en cours de création --- "

# --- Blocs optionnels
TITLE_PAGE_BLOCK=""
if [[ $ADD_TITLE -eq 1 ]]; then
  TITLE_PAGE_BLOCK=$'\n\\begin{titlepage}\n  \\centering\n  {\\Large \\textbf{Titre du Rapport}}\\par\n  \\vspace{1cm}\n  {\\large Sous-titre / sujet}\\par\n  \\vfill\n  {\\large Auteur : Prénom Nom}\\par\n  {\\large Date : \\today}\\par\n\\end{titlepage}\n'
fi

TOC_BLOCK=""
[[ $ADD_TOC -eq 1 ]] && TOC_BLOCK="\\tableofcontents
\\pdfbookmark[section]{Sommaire}{toc}
\\newpage
"

GLOSSARY_PRINT_BLOCK=""
if [[ $ADD_GLOSSARY -eq 1 ]]; then
  cat > "$REFS/glossaire.tex" <<'TEX'
% Définissez ici vos entrées de glossaire et acronymes
% \newacronym{crct}{CRCT}{Centre de Recherche en Cancérologie de Toulouse}
% \newglossaryentry{cancer}{name=cancer, description={Le cancer désigne l'ensemble des maladies provoquées par la transformation de cellules qui deviennent anormales et prolifèrent de façon excessive.}}
TEX
  GLOSSARY_PRINT_BLOCK="\\section*{Glossaire et acronymes}
\\input{references/glossaire}
\\printglossary[type=\\acronymtype, title={Liste des acronymes}]
\\printglossary[title={Glossaire}]
\\newpage
"
fi

APPENDIX_BLOCK=""
[[ $ADD_APPENDIX -eq 1 ]] && APPENDIX_BLOCK="\\appendix
\\section{Annexe}
% Contenu de l'annexe
"

# --- Assemble rapport.tex
BIBLIO_PRINT_BLOCK=""
[[ $ADD_BIB -eq 1 ]] && BIBLIO_PRINT_BLOCK="\\printbibliography
\\newpage
"

cat > "$SRC/rapport.tex" <<TEX
\documentclass[10pt,a4paper]{report}

\\input{../../help/preamble.base}

\\title{Titre du Rapport}
\\author{Prénom Nom}
\\date{\\today}

\\begin{document}

$TITLE_PAGE_BLOCK


$TOC_BLOCK

\\chapter{Introduction}
% Votre texte ici.

\\chapter{Méthodes}
% Votre texte ici.

\\chapter{Résultats}
% Votre texte ici.

\\chapter{Discussion}
% Votre texte ici.

$BIBLIO_PRINT_BLOCK
$GLOSSARY_PRINT_BLOCK
$APPENDIX_BLOCK

\\end{document}
TEX

# --- build.sh généré selon options

cat > "$SRC/build.sh" <<'TEMPLATE'
#!/usr/bin/env bash
set -euo pipefail
# build.sh — compile src/rapport.tex avec nom de sortie personnalisé

JOBNAME="__JOBNAME__"
MAIN="rapport.tex"
SRCDIR="__DIR__"
OUTDIR="PDF"
USE_TOC=__USE_TOC__
USE_GLOSSARY=__USE_GLOSSARY__
USE_BIB=__USE_BIB__

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
TEMPLATE

# Injecte variables dans build.sh
sed -i "s|__JOBNAME__|${JOBNAME}|g" "$SRC/build.sh"
sed -i "s|__DIR__|${SRC}|g" "$SRC/build.sh"
sed -i "s|__USE_TOC__|$([[ $ADD_TOC -eq 1 ]] && echo 1 || echo 0)|g" "$SRC/build.sh"
sed -i "s|__USE_GLOSSARY__|$([[ $ADD_GLOSSARY -eq 1 ]] && echo 1 || echo 0)|g" "$SRC/build.sh"
sed -i "s|__USE_BIB__|$([[ $ADD_BIB -eq 1 ]] && echo 1 || echo 0)|g" "$SRC/build.sh"
chmod +x "$SRC/build.sh"

echo "DONE"
echo -e "\n[INFO]  Projet LaTeX créé dans: $SRC"
echo "[INFO]  Pour compiler: cd $SRC && ./build.sh"