#!/bin/bash

# 🎯 ControleViewer Pro - Script de Lancement
# Copyright 2025 ControleViewer Team

echo "🚀 ControleViewer Pro - Démarrage..."
echo "=================================="

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "Package.swift" ]; then
    echo "❌ Erreur: Package.swift non trouvé"
    echo "💡 Assurez-vous d'être dans le répertoire du projet"
    exit 1
fi

# Vérifier les prérequis
echo "🔍 Vérification des prérequis..."

# Vérifier Swift
if ! command -v swift &> /dev/null; then
    echo "❌ Swift n'est pas installé"
    echo "💡 Installez Xcode Command Line Tools: xcode-select --install"
    exit 1
fi

SWIFT_VERSION=$(swift --version | head -n1)
echo "✅ Swift détecté: $SWIFT_VERSION"

# Vérifier macOS
MACOS_VERSION=$(sw_vers -productVersion)
echo "✅ macOS Version: $MACOS_VERSION"

# Build du projet
echo ""
echo "🔨 Compilation du projet..."
echo "----------------------------"

if swift build; then
    echo "✅ Compilation réussie !"
else
    echo "❌ Erreur de compilation"
    echo "💡 Vérifiez les erreurs ci-dessus"
    exit 1
fi

# Permissions
echo ""
echo "🔐 Permissions requises..."
echo "-------------------------"
echo "⚠️  L'application nécessite les permissions suivantes :"
echo "   📹 Accès à la caméra"
echo "   🖱️  Contrôle d'accessibilité (Préférences Système > Sécurité)"
echo "   🌐 Accès réseau local (pour iPhone)"
echo ""

# Lancement
echo "🎯 Lancement de ControleViewer Pro..."
echo "====================================="
echo ""
echo "🧠 Intelligence Artificielle: ACTIVÉE"
echo "📹 Détection de Gestes: PRÊTE"
echo "⚙️  Configuration Avancée: DISPONIBLE"
echo "🎮 Contrôle Gestuel: EN ATTENTE"
echo ""
echo "💡 Utilisez Ctrl+C pour arrêter l'application"
echo ""

# Exécution avec gestion des erreurs
if swift run; then
    echo ""
    echo "👋 ControleViewer Pro s'est arrêté normalement"
else
    echo ""
    echo "❌ ControleViewer Pro s'est arrêté avec une erreur"
    echo "💡 Consultez les logs ci-dessus pour diagnostiquer"
fi

echo ""
echo "🎯 Merci d'avoir utilisé ControleViewer Pro !"
echo "============================================="
