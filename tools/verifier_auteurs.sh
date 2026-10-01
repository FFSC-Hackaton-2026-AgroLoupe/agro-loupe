#!/usr/bin/env bash
# Refuse les commits qui créditent un agent d'IA comme co-auteur.
#
# Certains outils — Cursor, Copilot, Claude Code — ajoutent d'eux-mêmes une
# ligne `Co-authored-by:` au message de commit. GitHub la lit et fait
# apparaître l'agent dans la liste des contributeurs du dépôt. Le travail est
# celui de la personne qui l'a dirigé ; c'est son nom qui doit y figurer.
#
# Usage :
#   tools/verifier_auteurs.sh                      # depuis origin/develop
#   tools/verifier_auteurs.sh <base> <head>        # plage explicite

set -euo pipefail

base="${1:-origin/develop}"
head="${2:-HEAD}"

# Noms et domaines des agents connus, cherchés sans tenir compte de la casse.
motifs='cursor|claude|copilot|codeium|windsurf|devin|chatgpt|openai|anthropic|noreply@google'

# Commits déjà fusionnés avant la mise en place de cette vérification.
# Les réécrire imposerait un `push --force` à toute l'équipe, pour un gain
# purement cosmétique. Ne jamais allonger cette liste : elle existe pour le
# passé, pas pour tolérer de nouveaux cas.
exceptions='c932577989d52237bcc1349df9a2f668550dd851'

echo "Plage vérifiée : $base..$head"

fautifs=''
for sha in $(git rev-list "$base..$head"); do
  if echo "$exceptions" | grep -q "$sha"; then
    continue
  fi

  message=$(git log -1 --format='%B' "$sha")
  coauteurs=$(echo "$message" | grep -i '^Co-authored-by:' || true)

  if [ -n "$coauteurs" ] && echo "$coauteurs" | grep -Eqi "$motifs"; then
    fautifs="$fautifs\n  $(git log -1 --format='%h %s' "$sha")\n    $(echo "$coauteurs" | tr '\n' ' ')"
  fi
done

if [ -n "$fautifs" ]; then
  echo
  echo "Co-auteur automatique détecté :"
  echo -e "$fautifs"
  echo
  echo "Pour corriger, sur votre branche :"
  echo "  git rebase -i $base      # marquer 'reword' sur le commit"
  echo "  # puis supprimer la ligne Co-authored-by du message"
  echo "  git push --force-with-lease"
  echo
  echo "Et pour que cela ne revienne pas :"
  echo "  Cursor   : Settings > Rules & Memories > désactiver le co-auteur"
  echo "  Copilot  : décocher l'ajout du co-auteur dans les réglages de commit"
  exit 1
fi

echo "Aucun co-auteur automatique."
