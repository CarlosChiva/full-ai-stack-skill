#!/bin/bash

SEARCH_DIR="${SEARCH_DIR:-$HOME/.config/opencode/agents}"
MODEL_VALUE=""
FILES_PROCESSED=0
FILES_UPDATED=0
FILES_SKIPPED=0

cleanup() {
    rm -f "$SEARCH_DIR/.temp_config.txt"
    exit 0
}
trap cleanup EXIT

# Función para listar modelos disponibles (no incrementa contadores)
list_without_stats() {
    local directory="${1:-$SEARCH_DIR}"
    [ ! -d "$directory" ] && return 1
    echo "📋 Modelos disponibles en $directory:"
    echo ""
    while IFS= read -r -d '' file; do
        agent=$(basename "$file" .md)
        model=$(grep -m 1 "^[[:space:]]*model:" "$file" 2>/dev/null | sed 's/^[[:space:]]*model:[[:space:]]*//' | cut -d' ' -f1)
        [ -n "$agent" ] && echo "  ✅ $(basename "$agent") → ${model:-}"
    done < <(find "$directory" -name "*.md" -type f -print0)
}

# Función para listar modelos (con resultados finales)
list_models() {
    local directory="${1:-$SEARCH_DIR}"
    [ ! -d "$directory" ] && return 1
    list_without_stats "$directory"
    # No mostrar resultados finales en listar
    [ $FILES_PROCESSED -gt 0 ] || [ $FILES_UPDATED -gt 0 ] || return 0
    echo ""
    echo "════════════════════════════════════════════════════════════════════════════════════════"
    echo "║  📊 Resultados Finales"
    echo "║"
    echo "╚══════════════════════════════════════════════════════════════════════════════════════"
    echo ""
    echo "  Agentes procesados: $FILES_PROCESSED"
    echo "  Actualizados: $FILES_UPDATED"
    echo "  Sin cambios/error: $FILES_SKIPPED"
    [ $FILES_UPDATED -gt 0 ] && echo "  ✅ Configuración completada" || echo "  ⚠️  No se realizaron cambios"
}

# Función para editar agentes específicos con provider/model
edit_agents() {
    local provider_model="$1"
    shift
    local agents=()
    
    # Re-colectar los agentes ignorando flags
    for arg in "$@"; do
        [ "$arg" = "--agents" ] && continue
        [ ! -n "$arg" ] && continue
        agents+=("$arg")
    done
    
    [ ${#agents[@]} -eq 0 ] && return 0
    
    echo "🔧 Editando agentes con modelo: $provider_model"
    echo ""
    
    for agent in "${agents[@]}"; do
        # Si no termina en .md, añade el sufijo
        if [[ ! "$agent" == *.md ]]; then
            agent="${agent}.md"
        fi
        [ ! -f "$SEARCH_DIR/$agent" ] && { echo "❌ $agent → No encontrado"; FILES_SKIPPED=$((FILES_SKIPPED + 1)); continue; }
        
        # Verificar si ya tiene el modelo
        if grep -qE "^[[:space:]]*model:[[:space:]]*$provider_model" "$SEARCH_DIR/$agent"; then
            echo "⏭️  $agent → Ya tiene asignado"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
            FILES_PROCESSED=$((FILES_PROCESSED + 1))
            continue
        fi
        
        # Actualizar el archivo
        sed -i "0,/^[[:space:]]*model:/s|\([[:space:]]*model:[[:space:]]*\).*|\1${provider_model}|" "$SEARCH_DIR/$agent"
        
        # Verificar si se actualizó correctamente
        if grep -qE "^[[:space:]]*model:[[:space:]]*$provider_model" "$SEARCH_DIR/$agent"; then
            updated_model=$(grep -m 1 "^[[:space:]]*model:" "$SEARCH_DIR/$agent" | sed 's/^[[:space:]]*model:[[:space:]]*//' | cut -d' ' -f1)
            echo "✅ $agent → Modelo actualizado a: $updated_model"
            FILES_UPDATED=$((FILES_UPDATED + 1))
        else
            echo "❌ $agent → Error al actualizar"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
        fi
        
        FILES_PROCESSED=$((FILES_PROCESSED + 1))
    done
}

# Funciones mantenidas para compatibilidad
show_agent_menu() {
    AGENTS=()
    agent_files=()
    
    # Recopilar todos los archivos .md
    while IFS= read -r -d '' file; do
        AGENTS+=("$(basename "$file" .md)")
        agent_files+=("$file")
    done < <(find "$SEARCH_DIR" -name "*.md" -type f -print0)

    if [ ${#AGENTS[@]} -eq 0 ]; then
        echo "❌ No se encontraron agentes en $SEARCH_DIR"
        exit 1
    fi

    # Crear selección numérica
    echo "🎯 Agentes disponibles:"
    echo ""
    for ((i = 0; i < ${#AGENTS[@]}; i++)); do
        printf "%2d. %-20s " $((i + 1)) "${AGENTS[$i]}"
        if [ -f "$SEARCH_DIR/${AGENTS[$i]}.md" ] && grep -qE "^[[:space:]]*model:" "$SEARCH_DIR/${AGENTS[$i]}.md"; then
            current_model=$(grep -m 1 "^[[:space:]]*model:" "$SEARCH_DIR/${AGENTS[$i]}.md" | sed 's/^[[:space:]]*model:[[:space:]]*//')
            echo "(Actual: $current_model)"
        else
            echo "(Sin model configurado)"
        fi
    done
    echo ""
    echo "Selecciona los agentes (escribe "all" para seleccionarlos todos):"
}

select_agents() {
    show_agent_menu
    read -r selection
    
    # Manejar selección múltiple
    if [[ "$selection" =~ ^[[:space:]]*$ ]]; then
        return
    fi

    # Verificar si seleccionó "todos"
    if [[ "$selection" =~ "all" ]] || [[ "$selection" =~ "ALL" ]]; then
        ALL_AGENTS=()
        while IFS= read -r -d '' file; do
            ALL_AGENTS+=("$(basename "$file" .md)")
        done < <(find "$SEARCH_DIR" -name "*.md" -type f -print0)
        SELECTED_AGENTS=("${ALL_AGENTS[@]}")
    else
        IFS=' ' read -ra selected <<< "$selection"
        for idx in "${selected[@]}"; do
            if [ "$idx" -ge 1 ] && [ "$idx" -le ${#AGENTS[@]} ]; then
                SELECTED_AGENTS+=("${AGENTS[$((idx - 1))]}")
            fi
        done
    fi

    # Verificar que haya al menos uno
    if [ ${#SELECTED_AGENTS[@]} -eq 0 ]; then
        return
    fi

    # Mostrar resumen
    echo ""
    echo "✅ Agentes seleccionados: ${#SELECTED_AGENTS[@]}"
    for agent in "${SELECTED_AGENTS[@]}"; do
        echo "      - $agent"
    done
    echo ""
}

confirm_changes() {
    echo "¿Deseas aplicar los mismos cambios a TODOS los agentes seleccionados?"
    read -p "> [1] Aplicar a todos / [2] Cambiar cada uno individualmente: " choice
    
    case $choice in
        1|"")
            apply_same_to_all
            ;;
        2)
            change_individual
            ;;
        *)
            echo "❌ Opción inválida"
            confirm_changes
            ;;
    esac
}

apply_same_to_all() {
    echo ""
    echo "📝 Actualizando todos los agentes seleccionados:"
    echo 

    for agent in "${SELECTED_AGENTS[@]}"; do
        agent_file="$SEARCH_DIR/${agent}.md"
        
        if [ ! -f "$agent_file" ]; then
            echo "❌ $agent → No se encontraron"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
            continue
        fi

        # Verificar si el agente ya tiene el modelo actual
        if grep -qE "^[[:space:]]*model:[[:space:]]*$MODEL_VALUE" "$agent_file"; then
            echo "⏭️  $agent → Ya tiene el modelo asignado"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
            continue
        fi

        # Actualizar el archivo
        sed -i "0,/^[[:space:]]*model:/s|\([[:space:]]*model:[[:space:]]*\).*|\1${MODEL_VALUE}|" "$agent_file"
        
        # Verificar si se actualizó correctamente
        if grep -qE "^[[:space:]]*model:[[:space:]]*$MODEL_VALUE" "$agent_file"; then
            echo "✅ $agent → Modelo actualizado a: $MODEL_VALUE"
            FILES_UPDATED=$((FILES_UPDATED + 1))
        else
            echo "❌ $agent → Error al actualizar"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
        fi
        
        FILES_PROCESSED=$((FILES_PROCESSED + 1))
    done
}

change_individual() {
    echo ""
    echo "🔧 Modificación individual:"
    echo ""
    
    for agent in "${SELECTED_AGENTS[@]}"; do
        agent_file="$SEARCH_DIR/${agent}.md"
        current_model=$(grep -m 1 "^[[:space:]]*model:" "$agent_file" 2>/dev/null | sed 's/^[[:space:]]*model:[[:space:]]*//' | cut -d' ' -f1)
        
        echo "📝 Agente: $agent"
        echo "   Modelo actual: ${current_model:-No configurado}"
        echo ""
        
        read -p "   Nuevo modelo (proveedor/nombre, o enter para mantener): " new_model
        
        # Si el usuario no ingresa nada, mantener el modelo actual o dejarlo vacío
        if [[ -z "$new_model" ]]; then
            echo "⏭️  $agent → Se mantiene el modelo actual"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
            continue
        fi

        # Verificar formato
        if [[ ! "$new_model" =~ ^[^/]+/[^/]+$ ]]; then
            echo "❌ Format invalido. Debe ser 'proveedor/nombre'"
        else
            # Actualizar el archivo
            sed -i "0,/^[[:space:]]*model:/s|\([[:space:]]*model:[[:space:]]*\).*|\1${new_model}|" "$agent_file"
            
            # Verificar si se actualizó
            # Extraer nuevo valor
            updated_model=$(grep -m 1 "^[[:space:]]*model:" "$agent_file" | sed 's/^[[:space:]]*model:[[:space:]]*//' | cut -d' ' -f1)
            echo "✅ $agent → Modelo actualizado a: $updated_model"
            FILES_UPDATED=$((FILES_UPDATED + 1))
        fi
        FILES_PROCESSED=$((FILES_PROCESSED + 1))
        echo ""
    done
}

# Flujo principal
if [ $# -eq 0 ]; then
    echo "Uso: $0 --list [DIRECTORIO]"
    echo "     $0 --edit <provider/model> --agents <archivo1.md archivo2.md ...>"
    exit 1
fi

case "$1" in
    --list|-l)
        # Usa directorio por defecto si no se pasa nada
        [ -n "$2" ] && [ ! -d "$2" ] && SEARCH_DIR="$2"
        list_models "$SEARCH_DIR"
        exit 0
        ;;
    --edit|-e)
        # Reiniciar contadores para edición
        FILES_PROCESSED=0
        FILES_UPDATED=0
        FILES_SKIPPED=0
        [ -n "$2" ] && MODEL_VALUE="$2"
        case "$3" in
            --agents|-a)
                shift 2
                edit_agents "$MODEL_VALUE" "$@"
                # Mostrar resultados siempre después de edición
                echo ""
                echo "════════════════════════════════════════════════════════════════════════════════════════════"
                echo "║  📊 Resultados Finales"
                echo "║"
                echo "╚═════════════════════════════════════════════════════════════════════════════════════════════"
                echo ""
                echo "  Agentes procesados: $FILES_PROCESSED"
                echo "  Actualizados: $FILES_UPDATED"
                echo "  Sin cambios/error: $FILES_SKIPPED"
                [ $FILES_UPDATED -gt 0 ] && echo "  ✅ Configuración completada" || echo "  ⚠️  No se realizaron cambios"
                ;;
            *)
                # Usa SEARCH_DIR/*.md por defecto si no especifican --agents
                edit_agents "$MODEL_VALUE" "$SEARCH_DIR"/*.md
                echo ""
                echo "════════════════════════════════════════════════════════════════════════════════════════════"
                echo "║  📊 Resultados Finales"
                echo "║"
                echo "╚═════════════════════════════════════════════════════════════════════════════════════════════"
                echo ""
                echo "  Agentes procesados: $FILES_PROCESSED"
                echo "  Actualizados: $FILES_UPDATED"
                echo "  Sin cambios/error: $FILES_SKIPPED"
                [ $FILES_UPDATED -gt 0 ] && echo "  ✅ Configuración completada" || echo "  ⚠️  No se realizaron cambios"
                ;;
        esac
        ;;
    *)
        echo "Uso: $0 --list [DIRECTORIO]"
        echo "     $0 --edit <provider/model> --agents <archivo1.md archivo2.md ...>"
        exit 1
        ;;
esac
