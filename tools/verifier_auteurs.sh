#!/usr/bin/env bash
# Refuse les commits qui créditent un agent d'IA.
#
# Deux voies possibles, et les deux sont contrôlées :
#
#   1. La ligne `Co-authored-by:` que certains outils — Cursor, Copilot,
#      Claude Code — ajoutent d'eux-mêmes au message. GitHub la lit et fait
#      apparaître l'agent dans la liste des contributeurs du dépôt.
#   2. L'identité du commit elle-même, si quelqu'un règle son `user.name` ou
#      son `user.email` sur celui d'un agent. Le premier contrôle ne verrait
#      alors rien.
#
# Le travail est celui de la personne qui l'a dirigé ; c'est son nom qui doit
# y figurer.
#
# Usage :
#   tools/verifier_auteurs.sh                   # depuis origin/develop
#   tools/verifier_auteurs.sh <base> <head>     # plage explicite

set -euo pipefail

base="${1:-origin/develop}"
head="${2:-HEAD}"

# Noms et domaines des agents connus, cherchés sans tenir compte de la casse.
motifs='cursor|claude|copilot|codeium|windsurf|devin|chatgpt|openai|anthropic'

# Aucune exception. L'historique a été réécrit le 1er octobre 2026 pour
# retirer le seul commit concerné : il n'y a plus de passe-droit, ni pour le
# passé ni pour personne. Ne pas en rouvrir — corriger un message coûte une
# minute, le laisser passer coûte une réécriture d'historique et une
# resynchronisation de toute l'équipe.

echo "Plage vérifiée : $base..$head"

fautifs=0

for sha in $(git rev-list "$base..$head"); do
  resume=$(git log -1 --format='%h %s' "$sha")

  # 1. La ligne de co-auteur ajoutée par l'outil.
  coauteurs=$(git log -1 --format='%B' "$sha" | grep -i '^Co-authored-by:' || true)
  if [ -n "$coauteurs" ] && printf '%s' "$coauteurs" | grep -Eqi "$motifs"; then
    echo
    echo "  $resume"
    printf '    %s\n' "$coauteurs"
    fautifs=$((fautifs + 1))
  fi

  # 2. L'identité du commit, auteur comme committer.
  identites=$(git log -1 --format='%an <%ae>%n%cn <%ce>' "$sha")
  if printf '%s' "$identites" | grep -Eqi "$motifs"; then
    echo
    echo "  $resume"
    printf '    identité : %s\n' "$identites"
    fautifs=$((fautifs + 1))
  fi
done

if [ "$fautifs" -gt 0 ]; then
  echo
  echo "$fautifs commit(s) créditent un agent."
  echo
  echo "Pour corriger, sur votre branche :"
  echo "  git rebase -i $base      # marquer 'reword' sur le commit"
  echo "  # puis supprimer la ligne Co-authored-by du message"
  echo "  git push --force-with-lease"
  echo
  echo "Et pour que cela ne revienne pas :"
  echo "  Cursor  : Settings > Rules & Memories > désactiver le co-auteur"
  echo "  Copilot : décocher l'ajout du co-auteur dans les réglages de commit"
  exit 1
fi

echo "Aucun commit ne crédite d'agent."
