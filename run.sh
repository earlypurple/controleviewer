#!/bin/bash

# Script de lancement ControleViewer
# Ce script compile et lance l'application de contrôle Mac par gestes

echo "🎬 ControleViewer - Contrôle Mac par Gestes et iPhone"
echo "=================================================="

# Vérifier si nous sommes dans le bon répertoire
if [ ! -f "Package.swift" ]; then
    echo "❌ Erreur: Package.swift non trouvé. Veuillez lancer ce script depuis le répertoire du projet."
    exit 1
fi

# Compilation
echo "🔨 Compilation de l'application..."
if swift build; then
    echo "✅ Compilation réussie!"
else
    echo "❌ Erreur lors de la compilation. Consultez les messages d'erreur ci-dessus."
    exit 1
fi

# Vérification des permissions d'accessibilité
echo ""
echo "⚠️  PERMISSIONS REQUISES:"
echo "1. Caméra: Autorisée automatiquement lors du premier lancement"
echo "2. Accessibilité: Allez dans Préférences Système > Sécurité et confidentialité > Accessibilité"
echo "   et ajoutez cette application à la liste des applications autorisées."
echo ""

# Proposition d'ouverture des préférences système
read -p "Voulez-vous ouvrir les Préférences Système maintenant? (y/N): " open_prefs
if [[ $open_prefs =~ ^[Yy]$ ]]; then
    open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
fi

echo ""
read -p "Appuyez sur Entrée pour lancer l'application..."

# Lancement de l'application
echo "🚀 Lancement de ControleViewer..."
echo ""
echo "UTILISATION:"
echo "- Cliquez 'Démarrer caméra' pour activer la détection de gestes"
echo "- Activez 'Contrôle par gestes' pour permettre le contrôle"
echo "- Utilisez 'Démarrer découverte iPhone' pour connecter votre iPhone"
echo ""
echo "GESTES RECONNUS:"
echo "👆 Index pointé = Déplacer curseur"
echo "✊ Poing fermé = Clic gauche"
echo "✌️ Signe de paix = Clic droit"
echo "✋ Main ouverte = Scroll"
echo ""

# Lancer l'application
swift run controleviewer
