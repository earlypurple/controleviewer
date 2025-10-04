#!/bin/bash
echo "🚀 Compilation GestureControl Pro..."
swift build -Xswiftc -warnings-as-errors=false -Xswiftc -strict-concurrency=minimal 2>&1 | grep -v "warning:" || swift build
if [ $? -eq 0 ]; then
    echo "✅ Build réussi!"
    echo "▶️  Lancement de l'application..."
    swift run
else
    echo "❌ Erreurs de compilation"
    exit 1
fi
