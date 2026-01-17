#!/usr/bin/env bash
# ZMK Studio Compliance Validation

ERRORS=0
WARNINGS=0

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

error() {
    echo -e "${RED}ERROR:${NC} $1" >&2
    ((ERRORS++)) || true
}

warn() {
    echo -e "${YELLOW}WARNING:${NC} $1" >&2
    ((WARNINGS++)) || true
}

info() {
    echo -e "${GREEN}INFO:${NC} $1"
}

heading() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check build.yaml for Studio snippet
check_build_yaml() {
    local build_file="build.yaml"

    if [ ! -f "$build_file" ]; then
        error "build.yaml not found"
        return
    fi

    heading "Checking build.yaml for ZMK Studio configuration"

    # Check for studio-rpc-usb-uart snippet
    if ! grep -q 'snippet:.*studio-rpc-usb-uart' "$build_file"; then
        error "build.yaml: Missing 'snippet: studio-rpc-usb-uart' required for ZMK Studio support"
        echo "  Add this to each board configuration in build.yaml:"
        echo "    snippet: studio-rpc-usb-uart"
    else
        info "build.yaml: Found studio-rpc-usb-uart snippet ✓"
    fi

    # Count configurations with and without snippet
    local total_configs
    local studio_configs

    total_configs=$(grep -c '^\s*- board:' "$build_file" || echo 0)
    studio_configs=$(grep -B 5 'snippet:.*studio-rpc-usb-uart' "$build_file" | grep -c '^\s*- board:' || echo 0)

    if [ "$total_configs" -gt 0 ]; then
        info "Found $studio_configs/$total_configs board configurations with Studio support"

        if [ "$studio_configs" -lt "$total_configs" ]; then
            warn "Not all board configurations have ZMK Studio support enabled"
        fi
    fi
}

# Check keymap files for Studio compliance
check_keymap_labels() {
    local keymap_files=()

    # Find all keymap files
    mapfile -t keymap_files < <(find config -name "*.keymap" 2>/dev/null || true)

    if [ ${#keymap_files[@]} -eq 0 ]; then
        warn "No keymap files found in config/"
        return
    fi

    for keymap in "${keymap_files[@]}"; do
        heading "Checking $keymap for layer labels"

        # Extract layer definitions and check for labels
        local in_keymap=0
        local current_layer=""
        local layer_has_label=0
        local unlabeled_layers=()

        while IFS= read -r line; do
            # Detect keymap start
            if echo "$line" | grep -qE '^\s*keymap\s*\{'; then
                in_keymap=1
                continue
            fi

            # Detect keymap end
            if [ $in_keymap -eq 1 ] && echo "$line" | grep -qE '^\s*\};?\s*$'; then
                # Check if last layer had label
                if [ -n "$current_layer" ] && [ $layer_has_label -eq 0 ]; then
                    unlabeled_layers+=("$current_layer")
                fi
                break
            fi

            if [ $in_keymap -eq 1 ]; then
                # Detect layer definition
                if echo "$line" | grep -qE '^\s*[a-zA-Z_][a-zA-Z0-9_-]*\s*\{'; then
                    # Save previous layer if it didn't have a label
                    if [ -n "$current_layer" ] && [ $layer_has_label -eq 0 ]; then
                        unlabeled_layers+=("$current_layer")
                    fi

                    current_layer=$(echo "$line" | sed -E 's/^\s*([a-zA-Z_][a-zA-Z0-9_-]*)\s*\{.*/\1/')
                    layer_has_label=0
                fi

                # Check for label in current layer
                if echo "$line" | grep -qE '^\s*label\s*='; then
                    layer_has_label=1
                    label_value=$(echo "$line" | sed -n 's/.*label = "\([^"]*\)".*/\1/p')

                    # Validate label length (Studio UI works best with short labels)
                    if [ ${#label_value} -gt 10 ]; then
                        warn "$keymap: Layer '$current_layer' has long label '$label_value' (${#label_value} chars). Keep under 10 for best Studio UI display."
                    fi
                fi
            fi
        done < "$keymap"

        # Report unlabeled layers
        if [ ${#unlabeled_layers[@]} -gt 0 ]; then
            error "$keymap: The following layers are missing 'label' property (required for ZMK Studio):"
            for layer in "${unlabeled_layers[@]}"; do
                echo "  - $layer"
            done
            echo ""
            echo "  Add labels like this:"
            echo "    $layer {"
            echo "        bindings = <...>;"
            echo "        label = \"my_layer\";"
            echo "    };"
        else
            info "$keymap: All layers have labels ✓"
        fi

        # Check for Studio-incompatible features (advanced warning)
        if grep -qE '(#ifdef|#ifndef|#if|CONFIG_)' "$keymap"; then
            warn "$keymap: Contains preprocessor directives. These work in firmware but cannot be modified via Studio."
        fi

        if grep -qE 'zmk,behavior-macro' "$keymap"; then
            info "$keymap: Contains macros. These can be triggered via Studio but not edited."
        fi
    done
}

# Check for common Studio connectivity issues
check_studio_connectivity_requirements() {
    heading "Checking Studio connectivity requirements"

    # Check if USB snippet is used (required for Studio communication)
    if [ -f "build.yaml" ]; then
        if grep -q 'studio-rpc-usb-uart' "build.yaml"; then
            info "USB UART snippet configured for Studio communication ✓"
        else
            error "Missing studio-rpc-usb-uart snippet in build.yaml"
        fi
    fi

    # Remind about common Studio connection requirements
    echo ""
    echo "Studio Connection Checklist:"
    echo "  1. Firmware built with studio-rpc-usb-uart snippet ✓ (checked above)"
    echo "  2. Connect keyboard via USB (Bluetooth not supported for Studio)"
    echo "  3. Use a WebUSB-compatible browser (Chrome/Edge)"
    echo "  4. Visit https://zmk.studio to connect"
}

# Main execution
main() {
    echo ""
    heading "ZMK Studio Compliance Validation"
    echo ""

    check_build_yaml
    echo ""
    check_keymap_labels
    echo ""
    check_studio_connectivity_requirements

    # Summary
    echo ""
    echo "================================"
    if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
        echo -e "${GREEN}✓ Studio compliance check passed!${NC}"
        exit 0
    elif [ $ERRORS -eq 0 ]; then
        echo -e "${YELLOW}⚠ Studio compliance check passed with $WARNINGS warning(s)${NC}"
        exit 0
    else
        echo -e "${RED}✗ Studio compliance check failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
        echo ""
        echo "Fix the errors above to ensure ZMK Studio compatibility."
        exit 1
    fi
}

main "$@"
