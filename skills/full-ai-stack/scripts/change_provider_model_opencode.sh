#!/bin/bash

# ─────────────────────────────────────────────
#  agents-model-manager.sh
#  Gestiona el campo 'model' de agentes de
#  opencode (~/.config/opencode/agents/) y
#  Claude Code (~/.claude/agents/)
# ─────────────────────────────────────────────

OPENCODE_DIR="${OPENCODE_DIR:-$HOME/.config/opencode/agents}"
CLAUDECODE_DIR="${CLAUDECODE_DIR:-$HOME/.claude/agents}"
SEARCH_DIR=""
TOOL=""
MODEL_VALUE=""
FILES_PROCESSED=0
FILES_UPDATED=0
FILES_SKIPPED=0

cleanup() {
    rm -f "$SEARCH_DIR/.temp_config.txt"
    exit 0
}
trap cleanup EXIT

# ── Ayuda ────────────────────────────────────
usage() {
    echo ""
    echo "  Uso:"
    echo "    $0 --tool <opencode|claudecode> --list"
    echo "    $0 --tool <opencode|claudecode> --edit <modelo> [--agents <ag1 ag2 ...>]"
    echo ""
    echo "  Opciones:"
    echo "    --tool opencode      Apunta a ~/.config/opencode/agents/"
    echo "    --tool claudecode    Apunta a ~/.claude/agents/"
    echo ""
    echo "  Formato del modelo:"
    echo "    opencode   →  proveedor/nombre   (ej: anthropic/claude-sonnet-4-5)"
    echo "    claudecode →  alias corto        (ej: sonnet | opus | haiku)"
    echo "                  o model string     (ej: claude-sonnet-4-5-20251001)"
    echo ""
    echo "  Ejemplos:"
    echo "    $0 --tool opencode    --list"
    echo "    $0 --tool claudecode  --list"
    echo "    $0 --tool opencode    --edit anthropic/claude-opus-4-6"
    echo "    $0 --tool claudecode  --edit sonnet --agents reviewer.md debugger.md"
    echo ""
    exit 1
}

# ── Selección de directorio según herramienta ─
resolve_tool() {
    case "$TOOL" in
        opencode)
            SEARCH_DIR="$OPENCODE_DIR"
            ;;
        claudecode)
            SEARCH_DIR="$CLAUDECODE_DIR"
            ;;
        *)
            echo "❌ Herramienta desconocida: '$TOOL'. Usa 'opencode' o 'claudecode'."
            usage
            ;;
    esac

    if [ ! -d "$SEARCH_DIR" ]; then
        echo "❌ Directorio no encontrado: $SEARCH_DIR"
        exit 1
    fi
}

# ── Validación de formato de modelo ───────────
validate_model() {
    local model="$1"
    if [ "$TOOL" = "opencode" ]; then
        if [[ ! "$model" =~ ^[^/]+/[^/]+$ ]]; then
            echo "❌ Formato inválido para opencode. Debe ser 'proveedor/nombre' (ej: anthropic/claude-sonnet-4-5)"
            exit 1
        fi
    fi
    # Para claudecode se acepta cualquier string (sonnet, opus, haiku, model-string completo)
}

# ── Listar agentes ────────────────────────────
list_models() {
    echo ""
    echo "  🔧 Herramienta : $TOOL"
    echo "  📁 Directorio  : $SEARCH_DIR"
    echo ""
    echo "  📋 Agentes configurados:"
    echo ""

    local found=0
    while IFS= read -r -d '' file; do
        found=1
        agent=$(basename "$file" .md)
        model=$(grep -m 1 "^[[:space:]]*model:" "$file" 2>/dev/null \
                | sed 's/^[[:space:]]*model:[[:space:]]*//' \
                | cut -d' ' -f1)
        printf "    ✅ %-25s → %s\n" "$agent" "${model:-(sin modelo)}"
    done < <(find "$SEARCH_DIR" -name "*.md" -type f -print0)

    [ $found -eq 0 ] && echo "    ⚠️  No se encontraron agentes en $SEARCH_DIR"
    echo ""
}

# ── Editar agentes ────────────────────────────
edit_agents() {
    local agents=("$@")

    echo ""
    echo "  🔧 Herramienta : $TOOL"
    echo "  📁 Directorio  : $SEARCH_DIR"
    echo "  🎯 Modelo      : $MODEL_VALUE"
    echo ""
    echo "  ✏️  Editando agentes:"
    echo ""

    for agent in "${agents[@]}"; do
        # Normalizar: añadir .md si falta
        [[ "$agent" != *.md ]] && agent="${agent}.md"

        # Resolver ruta: si el usuario pasó ruta absoluta o relativa, usarla tal cual;
        # si es solo nombre de archivo, buscarlo en SEARCH_DIR (recursivo)
        local agent_file=""
        if [ -f "$agent" ]; then
            agent_file="$agent"
        else
            # Búsqueda recursiva dentro de SEARCH_DIR
            agent_file=$(find "$SEARCH_DIR" -name "$(basename "$agent")" -type f 2>/dev/null | head -1)
        fi

        local label
        label=$(basename "${agent_file:-$agent}" .md)

        if [ -z "$agent_file" ]; then
            printf "    ❌ %-25s → No encontrado\n" "$label"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
            continue
        fi

        # ¿Ya tiene el modelo?
        if grep -qE "^[[:space:]]*model:[[:space:]]*${MODEL_VALUE}[[:space:]]*$" "$agent_file"; then
            printf "    ⏭️  %-25s → Ya tiene ese modelo\n" "$label"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
            FILES_PROCESSED=$((FILES_PROCESSED + 1))
            continue
        fi

        # Actualizar
        sed -i "0,/^[[:space:]]*model:/s|\([[:space:]]*model:[[:space:]]*\).*|\1${MODEL_VALUE}|" "$agent_file"

        if grep -qE "^[[:space:]]*model:[[:space:]]*${MODEL_VALUE}[[:space:]]*$" "$agent_file"; then
            printf "    ✅ %-25s → Actualizado a: %s\n" "$label" "$MODEL_VALUE"
            FILES_UPDATED=$((FILES_UPDATED + 1))
        else
            printf "    ❌ %-25s → Error al actualizar\n" "$label"
            FILES_SKIPPED=$((FILES_SKIPPED + 1))
        fi

        FILES_PROCESSED=$((FILES_PROCESSED + 1))
    done
}

# ── Resultados finales ────────────────────────
show_results() {
    echo ""
    echo "  ════════════════════════════════════════════"
    echo "    📊 Resultados"
    echo "  ════════════════════════════════════════════"
    echo "    Procesados  : $FILES_PROCESSED"
    echo "    Actualizados: $FILES_UPDATED"
    echo "    Sin cambios : $FILES_SKIPPED"
    if [ $FILES_UPDATED -gt 0 ]; then
        echo "    ✅ Configuración completada"
    else
        echo "    ⚠️  No se realizaron cambios"
    fi
    echo ""
}

# ── Parser de argumentos ──────────────────────
[ $# -eq 0 ] && usage

AGENTS_LIST=()
PARSE_AGENTS=false
ACTION=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --tool|-t)
            TOOL="$2"; shift 2 ;;
        --list|-l)
            ACTION="list"; shift ;;
        --edit|-e)
            ACTION="edit"; MODEL_VALUE="$2"; shift 2 ;;
        --agents|-a)
            PARSE_AGENTS=true; shift ;;
        *)
            if $PARSE_AGENTS; then
                AGENTS_LIST+=("$1")
            else
                echo "❌ Argumento desconocido: $1"
                usage
            fi
            shift ;;
    esac
done

# ── Validaciones básicas ──────────────────────
[ -z "$TOOL" ]   && { echo "❌ Falta --tool <opencode|claudecode>"; usage; }
[ -z "$ACTION" ] && { echo "❌ Falta --list o --edit <modelo>"; usage; }

resolve_tool

# ── Ejecutar acción ───────────────────────────
case "$ACTION" in
    list)
        list_models
        ;;
    edit)
        [ -z "$MODEL_VALUE" ] && { echo "❌ Falta el valor del modelo tras --edit"; usage; }
        validate_model "$MODEL_VALUE"

        if [ ${#AGENTS_LIST[@]} -eq 0 ]; then
            # Sin --agents: afectar todos los .md del directorio (recursivo)
            while IFS= read -r -d '' file; do
                AGENTS_LIST+=("$file")
            done < <(find "$SEARCH_DIR" -name "*.md" -type f -print0)
        fi

        edit_agents "${AGENTS_LIST[@]}"
        show_results
        ;;
esac