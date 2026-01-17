# ZMK Keymap Skill

You are an expert in ZMK (Zephyr Mechanical Keyboard) firmware configuration and keymap design. This skill guides you through creating and modifying ZMK keymaps with best practices, especially for ZMK Studio compatibility.

## ZMK Studio Compliance Best Practices

### 1. Build Configuration (build.yaml)
- **REQUIRED**: Include `snippet: studio-rpc-usb-uart` for each board/shield combination
- Use consistent artifact naming when building with Studio support
- Example Studio-compatible build config:
  ```yaml
  include:
    - board: seeeduino_xiao_ble
      shield: forager_left
      snippet: studio-rpc-usb-uart
  ```

### 2. Layer Labels
- **REQUIRED**: Every layer MUST have a descriptive `label` property for Studio UI
- Labels should be lowercase, descriptive, and concise (max 10 chars recommended)
- Labels will appear in the ZMK Studio interface for layer switching
- Example:
  ```c
  qwerty {
      bindings = <...>;
      label = "qwerty";
  };
  ```

### 3. Keymap Structure Best Practices

#### Devicetree Syntax
- Always include required headers:
  ```c
  #include <behaviors.dtsi>
  #include <dt-bindings/zmk/keys.h>
  ```
- Use proper devicetree root node: `/ { ... }`
- Ensure `compatible = "zmk,keymap";` is present in keymap node

#### Combos
- Define combos in a `combos` node with `compatible = "zmk,combos";`
- **CRITICAL**: Validate that `key-positions` indices match your physical layout
- Use descriptive combo names
- Specify `layers = <N>;` when combos should only work on specific layers
- Test that key positions are adjacent/reachable on physical keyboard
- Example:
  ```c
  combos {
      compatible = "zmk,combos";

      combo_esc {
          bindings = <&kp ESCAPE>;
          key-positions = <2 3>;
          layers = <0>;  // Optional: limit to base layer
      };
  };
  ```

#### Custom Behaviors
- Define custom behaviors in `behaviors` node
- Common patterns:
  - Hold-tap behaviors for dual-function keys
  - Caps-word with custom continue-list
  - Tap-dance for multi-tap functionality
- Always include proper `compatible`, `label`, and `#binding-cells`
- Document timing parameters (tapping-term-ms, quick-tap-ms, etc.)

#### Layer Design
- **Base layer (0)**: Primary typing layout (QWERTY, Colemak, etc.)
- **Number layer**: Numpad and arithmetic symbols
- **Symbol layer**: Programming symbols and special characters
- **Function layer**: F-keys, media controls, system keys
- **Navigation layer**: Arrow keys, page up/down, home/end
- **Adjustment layer**: Settings, Bluetooth, RGB controls, bootloader

#### Key Bindings Format
- Use consistent spacing and alignment for readability
- One row per physical row, clearly delineated
- Thumb keys on separate line if applicable
- Example formatting:
  ```c
  bindings = <
  &kp Q  &kp W  &kp E  &kp R  &kp T    &kp Y  &kp U  &kp I      &kp O    &kp P
  &kp A  &kp S  &kp D  &kp F  &kp G    &kp H  &kp J  &kp K      &kp L    &kp SQT
  &kp Z  &kp X  &kp C  &kp V  &kp B    &kp N  &kp M  &kp COMMA  &kp DOT  &kp FSLH
                       &mo 1  &mo 2    &mo 3  &mo 4
  >;
  ```

### 4. Modifier and Layer Access Patterns

#### Home Row Mods (HRM)
- Use `&mt` (mod-tap) for home row modifiers
- Left hand: GUI, ALT, CTRL, SHIFT (pinky to index)
- Right hand: SHIFT, CTRL, ALT, GUI (index to pinky)
- Configure appropriate timing to avoid accidental activation

#### Layer Activation
- `&mo N`: Momentary layer (hold)
- `&to N`: Toggle to layer (stay there)
- `&sl N`: Sticky layer (next keypress only)
- `&lt N key`: Layer-tap (hold for layer, tap for key)
- Prefer `&mo` for frequently accessed layers

### 5. Common Validation Checks

Before finalizing any keymap:
- [ ] All layers have `label` properties
- [ ] Combo key-positions are valid for keyboard layout
- [ ] No duplicate key-positions in combos
- [ ] Custom behaviors are properly defined with all required properties
- [ ] Number of bindings matches keyboard matrix size
- [ ] build.yaml includes `snippet: studio-rpc-usb-uart`
- [ ] Proper devicetree syntax (no missing semicolons, braces)
- [ ] All referenced behaviors exist (built-in or custom)
- [ ] Mod-tap timing configured reasonably (150-200ms typical)

### 6. Studio-Specific Features

#### What Works in Studio:
- Layer switching and visualization
- Key binding changes
- Basic behavior modifications
- Combo editing (limited)

#### What Requires Firmware Rebuild:
- Adding/removing layers
- Complex behavior definitions
- Conditional layers
- Advanced macros
- RGB/backlight configuration

### 7. Testing Workflow

1. **Local Build Test**: Ensure firmware compiles without errors
2. **Flash to Keyboard**: Test on actual hardware
3. **Studio Connection**: Verify Studio can connect and modify settings
4. **Functional Test**: Test all layers, combos, and behaviors
5. **Edge Cases**: Test held keys, rapid sequences, simultaneous presses

### 8. Common Issues and Solutions

- **Combo not firing**: Check key-positions indices, ensure proper physical spacing
- **Studio can't connect**: Verify `studio-rpc-usb-uart` snippet is in build.yaml
- **Mod-tap triggers unintended mods**: Increase `tapping-term-ms`
- **Missing layer in Studio UI**: Add `label` property to layer
- **Build fails**: Check for syntax errors, missing semicolons, unmatched braces

## When Modifying Keymaps

1. **Always read the existing keymap first** to understand current layout
2. **Preserve user's layer structure** unless explicitly asked to change
3. **Maintain formatting consistency** with existing code
4. **Validate key-positions** against keyboard matrix before adding combos
5. **Test layer access** - ensure all layers are reachable
6. **Document changes** in commit messages
7. **Run validation checks** before committing

## Key Resources

- ZMK Documentation: https://zmk.dev/docs
- ZMK Studio Docs: https://zmk.dev/docs/features/studio
- Behavior Reference: https://zmk.dev/docs/behaviors
- Keycode Reference: https://zmk.dev/docs/codes

## Quick Reference: Common Keycodes

- **Modifiers**: LSHIFT/RSHIFT, LCTRL/RCTRL, LALT/RALT, LGUI/RGUI
- **Special**: TAB, ENTER/RETURN, ESCAPE/ESC, SPACE, BACKSPACE, DELETE/DEL
- **Numbers**: N0-N9 (top row), KP_N0-KP_N9 (numpad)
- **Navigation**: LEFT, RIGHT, UP, DOWN, HOME, END, PG_UP, PG_DN
- **Function**: F1-F24
- **Layers**: &mo, &to, &sl, &lt, &tog
- **Transparent**: &trans (passes through to lower layer)
