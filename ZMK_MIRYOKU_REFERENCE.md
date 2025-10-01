# ZMK Keymaps & Miryoku Layout Reference

A comprehensive reference for ZMK firmware keymap configuration and the Miryoku layout philosophy.

---

## Table of Contents

1. [ZMK Fundamentals](#zmk-fundamentals)
2. [ZMK Behaviors](#zmk-behaviors)
3. [Advanced Behavior Configuration](#advanced-behavior-configuration)
4. [Home Row Mods](#home-row-mods)
5. [Miryoku Layout Philosophy](#miryoku-layout-philosophy)
6. [Practical Patterns & Examples](#practical-patterns--examples)

---

## ZMK Fundamentals

### Devicetree Structure

ZMK keymaps use devicetree syntax for configuration. A basic keymap file structure:

```c
#include <behaviors.dtsi>
#include <dt-bindings/zmk/keys.h>

/ {
    keymap {
        compatible = "zmk,keymap";

        layer_name {
            bindings = <
                &kp Q  &kp W  &kp E  &kp R
                // ... more bindings
            >;
        };
    };
};
```

**Key Concepts:**
- Declarative configuration approach
- Uses preprocessor directives (`#include`, `#define`)
- Root node: `/`
- Keymap node must have `compatible = "zmk,keymap"`

### Layer System

**Core Principles:**
- Layers are numbered starting from 0 (base layer)
- Layer 0 is always enabled by default
- Multiple layers can be active simultaneously
- When a key is pressed, the **highest-valued active layer** determines behavior
- Layers are defined in order of appearance in the keymap

**Layer Numbering Best Practice:**
```c
#define BASE   0
#define NAV    1
#define NUM    2
#define SYM    3
#define FN     4
```

### Key Position Numbering

Key positions are numbered sequentially starting at 0, matching the order they appear in your keymap bindings:

```
 0  1  2  3  4     5  6  7  8  9
10 11 12 13 14    15 16 17 18 19
20 21 22 23 24    25 26 27 28 29
         30 31    32 33
```

This numbering is used in combos (`key-positions`) and positional hold-tap configurations.

---

## ZMK Behaviors

### Core Behaviors

| Behavior | Usage | Description |
|----------|-------|-------------|
| `&kp` | `&kp A` | Key press - sends keycode when pressed |
| `&mt` | `&mt LSHIFT A` | Mod-tap - modifier when held, keycode when tapped |
| `&lt` | `&lt NAV SPACE` | Layer-tap - activates layer when held, key when tapped |
| `&mo` | `&mo 1` | Momentary layer - enables layer while held |
| `&to` | `&to 2` | To layer - switches to layer, disables all others except base |
| `&tog` | `&tog 1` | Toggle layer - switches layer on/off each press |
| `&sl` | `&sl 1` | Sticky layer - activates layer for next keypress (default 1 sec) |
| `&sk` | `&sk LSHIFT` | Sticky key - holds modifier for next keypress |
| `&caps_word` | `&caps_word` | Caps word - auto-capitalizes until non-alpha key |
| `&key_repeat` | `&key_repeat` | Repeats last keycode |
| `&trans` | `&trans` | Transparent - passes through to lower layer |

### Special Behaviors

| Behavior | Description |
|----------|-------------|
| `&gresc` | Grave/Escape - Esc normally, Grave with Shift |
| `&sys_reset` | Soft reset the keyboard |
| `&bootloader` | Enter bootloader mode for flashing |
| `&bt` | Bluetooth controls (clear, select profile) |
| `&out` | Output selection (USB/BLE toggle) |

### Mouse Emulation

| Behavior | Description |
|----------|-------------|
| `&mkp` | Mouse key press (buttons) |
| `&mmv` | Mouse movement |
| `&msc` | Mouse scroll |

---

## Advanced Behavior Configuration

### Hold-Tap Behavior

Hold-tap is the foundation for mod-tap, layer-tap, and home row mods.

#### Flavors

| Flavor | Behavior |
|--------|----------|
| `hold-preferred` | Triggers hold when tapping-term expires OR another key is pressed |
| `balanced` | Triggers hold when tapping-term expires OR another key is pressed AND released |
| `tap-preferred` | Only triggers hold when tapping-term expires (ignores other key presses) |
| `tap-unless-interrupted` | Only triggers hold if another key is pressed before tapping-term expires |

#### Key Parameters

```c
behavior_name: behavior_name {
    compatible = "zmk,behavior-hold-tap";
    #binding-cells = <2>;

    // Core timing
    tapping-term-ms = <280>;          // How long to wait for tap vs hold decision
    quick-tap-ms = <175>;             // Allows rapid re-tapping

    // Advanced timing
    require-prior-idle-ms = <150>;    // Prevents hold if typing quickly

    // Positional hold-tap
    hold-trigger-key-positions = <5 6 7 8 9 15 16 17 18 19>;  // Keys that trigger hold
    hold-trigger-on-release;          // Delays evaluation until key release

    // Behavior on release
    retro-tap;                        // Triggers tap on release if no other key pressed

    flavor = "balanced";
    bindings = <&kp>, <&kp>;
};
```

**Timing Recommendations:**
- **tapping-term-ms**: 200-280ms (balanced typing speed)
- **quick-tap-ms**: 125-175ms (comfortable rapid repeat)
- **require-prior-idle-ms**: 150ms (prevents accidental holds during fast typing)

### Combos

Combos trigger actions when multiple keys are pressed simultaneously.

#### Basic Configuration

```c
combos {
    compatible = "zmk,combos";

    combo_esc {
        timeout-ms = <50>;                    // Time window for pressing all keys
        key-positions = <2 3>;                // Keys that trigger combo
        bindings = <&kp ESCAPE>;              // Action to perform
        layers = <0 1>;                       // Optional: limit to specific layers
    };
};
```

#### Advanced Parameters

```c
combo_advanced {
    timeout-ms = <50>;
    key-positions = <16 17>;
    bindings = <&kp ENTER>;

    slow-release;                             // Release only when all keys released
    require-prior-idle-ms = <150>;           // Prevent combo during fast typing
    layers = <0>;                            // Only active on base layer
};
```

#### Combo Helper Macro

```c
#define COMBO(NAME, BINDINGS, KEYPOS, LAYERS) \
    combo_##NAME { \
        timeout-ms = <50>; \
        bindings = <BINDINGS>; \
        key-positions = <KEYPOS>; \
        layers = <LAYERS>; \
    };

// Usage:
combos {
    compatible = "zmk,combos";
    COMBO(esc, &kp ESC, 2 3, 0)
    COMBO(enter, &kp ENTER, 16 17, 0)
};
```

### Sticky Keys & Layers

#### Sticky Key Configuration

```c
sticky_key: sticky_key {
    compatible = "zmk,behavior-sticky-key";
    #binding-cells = <1>;

    release-after-ms = <1000>;    // Auto-release after 1 second (default)
    quick-release;                // Release on next key press (vs release)
    lazy;                         // Activate right before next key press

    bindings = <&kp>;
};
```

#### Sticky Layer

```c
&sl 1    // Activates layer 1 for next keypress or 1 second
```

**Default Behavior:**
- Stays active for 1 second if no other key pressed
- Deactivates after one keypress
- Configurable via `release-after-ms`

### Macros

Macros automate sequences of key presses.

```c
macro_name: macro_name {
    compatible = "zmk,behavior-macro";
    #binding-cells = <0>;

    wait-ms = <40>;     // Delay between actions (default: CONFIG_ZMK_MACRO_DEFAULT_WAIT_MS)
    tap-ms = <40>;      // How long to hold each key (default: CONFIG_ZMK_MACRO_DEFAULT_TAP_MS)

    bindings = <&kp Z &kp M &kp K>;
};
```

**Timing Best Practices:**
- **Minimum 30ms** for wait-ms and tap-ms to avoid BLE protocol issues
- **Recommended 40ms** for reliable operation
- Can dynamically change timing: `&macro_wait_time 30`, `&macro_tap_time 20`

**Advanced Macro Controls:**
- `&macro_press` - Press and hold
- `&macro_release` - Release held key
- `&macro_tap` - Press and release
- `&macro_pause_for_release` - Wait for macro key release

### Caps Word

Auto-capitalizes text until a non-alpha key is pressed.

```c
caps_word_custom: caps_word_custom {
    compatible = "zmk,behavior-caps-word";
    #binding-cells = <0>;

    continue-list = <UNDERSCORE MINUS>;    // Keys that won't deactivate caps word
};
```

**Common continue-list keys:**
- `UNDERSCORE` - for `snake_case`
- `MINUS` - for `kebab-case`
- `NUMBER_1` through `NUMBER_0` - for alphanumeric constants
- `BACKSPACE`, `DELETE` - for corrections

**Example from forager.keymap:**
```c
caps_number: caps_number {
    compatible = "zmk,behavior-caps-word";
    #binding-cells = <0>;
    continue-list = <NUMBER_1 NUMBER_2 NUMBER_3 NUMBER_4 NUMBER_5
                     NUMBER_6 NUMBER_7 NUMBER_8 NUMBER_9 NUMBER_0
                     MINUS EQUAL PLUS FSLH DOT>;
};
```

---

## Home Row Mods

Home row mods place modifier keys (Shift, Control, Alt, GUI) on the home row as dual-function keys.

### Timeless Home Row Mods Configuration

The most popular and reliable configuration:

```c
behaviors {
    hml: homerow_mods_left {
        compatible = "zmk,behavior-hold-tap";
        #binding-cells = <2>;
        flavor = "balanced";
        tapping-term-ms = <280>;
        quick-tap-ms = <175>;
        require-prior-idle-ms = <150>;
        bindings = <&kp>, <&kp>;

        // Left hand triggers hold on right hand keys
        hold-trigger-key-positions = <5 6 7 8 9 15 16 17 18 19 25 26 27 28 29 33>;
        hold-trigger-on-release;
    };

    hmr: homerow_mods_right {
        compatible = "zmk,behavior-hold-tap";
        #binding-cells = <2>;
        flavor = "balanced";
        tapping-term-ms = <280>;
        quick-tap-ms = <175>;
        require-prior-idle-ms = <150>;
        bindings = <&kp>, <&kp>;

        // Right hand triggers hold on left hand keys
        hold-trigger-key-positions = <0 1 2 3 4 10 11 12 13 14 20 21 22 23 24 30>;
        hold-trigger-on-release;
    };
};
```

### Modifier Order: GACS vs CAGS

**GACS (GUI-Alt-Control-Shift):**
- Preferred for **Windows/Linux/BSD**
- Used by Miryoku layout

**CAGS (Control-Alt-GUI-Shift):**
- Preferred for **macOS**
- Accommodates macOS modifier usage patterns

### Home Row Mod Layout Example

```
Left Hand:                Right Hand:
A - GUI                   J - Shift
S - Alt                   K - Control
D - Control               L - Alt
F - Shift                 ; - GUI
```

**Implementation:**
```c
&hml LGUI A    &hmr RSHIFT J
&hml LALT S    &hmr RCTRL  K
&hml LCTRL D   &hmr RALT   L
&hml LSHIFT F  &hmr RGUI   SEMI
```

### Positional Hold-Tap Strategy

**Key Principle:** Separate left and right hand behaviors to prevent conflicts when pressing multiple home row mods.

- **Left hand behavior** (`hml`): hold-trigger-key-positions includes only **right hand** keys
- **Right hand behavior** (`hmr`): hold-trigger-key-positions includes only **left hand** keys

This ensures:
- You can hold left-hand Ctrl+Shift simultaneously
- Typing with same-hand combos triggers tap behavior
- Cross-hand holds trigger modifier behavior

### Bilateral Combinations

**Problem:** Fast typing can accidentally trigger modifiers when keys are chorded on the same hand.

**Solution:** Configure hold-trigger-key-positions to only activate hold on **opposite hand** key presses.

**Result:** Same-side chording always types letters; only cross-hand patterns trigger modifiers.

---

## Miryoku Layout Philosophy

### Core Principles

1. **Use layers instead of reaching** - Keep fingers at home position
2. **Use both hands instead of contortions** - Distribute work ergonomically
3. **Use the home positions as much as possible** - Minimize finger travel
4. **Make full use of the thumbs** - Strongest digits for layer activation
5. **Avoid unnecessary complication** - Simple, predictable behavior

### Layout Structure

**Physical Layout:**
- **3×5+3**: 5 columns, 3 rows, 3 thumb keys per hand
- **Home row**: Middle row
- **Maximum movement**: 1 unit from home position
- **Designed for**: 34-42 key split/ortho keyboards

```
     Left Hand                Right Hand
 Q   W   F   P   B        J   L   U   Y   ;
 A   R   S   T   G        M   N   E   I   O
 Z   X   C   D   V        K   H   ,   .   /
         Spc Tab Bsp    Ent Del Esc
```
*(Example with Colemak-DH)*

### Layer Organization

Miryoku defines **8 layers** with orthogonal purposes:

| Layer | Purpose | Activation | Primary Hand |
|-------|---------|------------|--------------|
| **Base** | Alpha keys (QWERTY/Colemak/etc) | Default | Both |
| **Nav** | Navigation & editing (arrows, copy/paste) | Right home thumb hold | Right hand keys, Left hand mods |
| **Mouse** | Mouse emulation | Secondary right thumb | Right hand |
| **Button** | Mouse buttons & wheel | Both Nav+Mouse | Both |
| **Media** | Media controls & system | Tertiary right thumb | Right hand |
| **Num** | Numbers & symbols | Left home thumb hold | Left hand keys, Right hand mods |
| **Sym** | Shifted symbols | Secondary left thumb | Left hand |
| **Fun** | Function keys (F1-F12) | Tertiary left thumb | Left hand |

**Key Insight:** Each layer has a **single purpose per hand**, accessed by the **opposite hand's thumb**.

### Home Row Mods (GACS Order)

**Left Hand (A-R-S-T on Colemak-DH):**
- Pinky: **G**UI (Super/Win/Cmd)
- Ring: **A**lt
- Middle: **C**ontrol
- Index: **S**hift

**Right Hand (N-E-I-O on Colemak-DH):**
- Index: **S**hift
- Middle: **C**ontrol
- Ring: **A**lt
- Pinky: **G**UI

**Mirrored Design:** Both hands have identical modifier patterns for symmetry and muscle memory.

### Thumb Key Assignments

Miryoku uses 3 thumb keys per hand with specific roles:

**Left Thumb:**
1. **Primary (home)**: Space / Num layer hold
2. **Secondary**: Tab / Sym layer hold
3. **Tertiary**: Backspace / Fun layer hold

**Right Thumb:**
1. **Primary (home)**: Enter / Nav layer hold
2. **Secondary**: Delete / Mouse layer hold
3. **Tertiary**: Escape / Media layer hold

**Pattern:** Each thumb key is dual-function (tap for key, hold for layer).

### Layer Activation Strategy

**Opposite-Hand Activation:**
- **Left-hand layers** (Num, Sym, Fun) → activated by **right thumb**
- **Right-hand layers** (Nav, Mouse, Media) → activated by **left thumb**

**Benefit:** Free hand executes layer functions while opposite thumb holds layer active.

### Navigation Layer Example

**Philosophy:** Right home row becomes arrow keys in inverted-T arrangement.

```
Nav Layer (Left thumb hold):
Left Hand (Mods):          Right Hand (Navigation):
GUI   Alt  Ctrl Shift      Redo  Paste Copy  Cut   Undo
                           Caps  Left  Down  Up    Right
                           Ins   Home  PgDn  PgUp  End
```

**Design Notes:**
- Down arrow on middle finger (home position)
- Mods on left hand enable Ctrl+Arrow, Shift+Arrow navigation
- Copy/paste/cut positioned for comfortable access
- Mirrors philosophy: "Use home positions as much as possible"

### Auto Shift

Miryoku implements auto-shift for numbers and symbols:
- **Tap**: Regular character
- **Hold**: Shifted character

This eliminates need for dedicated symbol layers for many use cases.

### Comprehensive Feature Set

Despite 34 keys, Miryoku provides:
- All keys from a TKL keyboard
- Media controls
- Mouse emulation
- Function keys (F1-F24)
- System controls (reset, bootloader)

**Achieved through:** Thoughtful layering and dual-function keys.

---

## Practical Patterns & Examples

### Layer Toggle Pattern

```c
// In base layer
&lt NAV SPACE    // Hold Space for Nav layer, tap for Space

// In nav layer
&trans           // Space still produces Space when nav is active
```

### Multi-Mod Shortcuts

With home row mods, complex shortcuts become simple:

```
Ctrl+Shift+T:     Hold D+F (left hand home row), press T
Ctrl+Alt+Delete:  Hold S+D (left hand), activate nav layer, press Delete
```

### Combo Strategies

**From forager.keymap:**

```c
// Common actions on comfortable positions
esc        { key-positions = <2 3>;   bindings = <&kp ESCAPE>; }      // W+E
backspace  { key-positions = <6 7>;   bindings = <&kp BACKSPACE>; }   // U+I
tab        { key-positions = <12 13>; bindings = <&kp TAB>; }          // D+F
enter      { key-positions = <16 17>; bindings = <&kp ENTER>; }        // M+N
del        { key-positions = <32 33>; bindings = <&kp DEL>; }          // Thumb keys
```

**Pattern:** Place common actions on comfortable, memorable two-key combos.

### Layer-Specific Combos

```c
dot {
    bindings = <&kp DOT>;
    key-positions = <30 31>;
    layers = <2>;    // Only active on NUM layer
};
```

**Use Case:** Different combo behaviors per layer (e.g., symbols on NUM layer, formatting on BASE).

### Transparent Keys

```c
colemak-dh {
    bindings = <
        &kp Q  &kp W  &kp F  &kp P  &kp B    &kp J  &kp L  &kp U  &kp Y  &kp SEMI
        &kp A  &kp R  &kp S  &kp T  &kp G    &kp M  &kp N  &kp E  &kp I  &kp O
        &kp Z  &kp X  &kp C  &kp D  &kp V    &kp K  &kp H  &kp COMMA &kp DOT &kp FSLH
                             &trans &trans   &trans &trans
    >;
};
```

**Use Case:** Alternative base layer that inherits thumb keys from default layer.

### Mirrored Modifiers Pattern

**Num Layer (from forager.keymap):**
```c
num {
    bindings = <
        // Left: Numbers and symbols
        &kp LBKT &kp N7 &kp N8 &kp N9 &kp RBKT

        // Right: Mirrored home row mods
        &trans &kp LSHFT &kp LCTRL &kp LALT &kp LGUI
    >;
};
```

**Pattern:** When left hand is typing (numbers), right hand provides modifiers.

### Smart Layer Design

**Single-Purpose Layers:**
- **NUM layer**: Left hand = numbers, right hand = mods
- **NAV layer**: Left hand = mods, right hand = navigation
- **FN layer**: Left hand = function keys, right hand = mods

**Consistency:** Same hand positions, different contexts.

### Custom Behavior Example

**From forager.keymap:**
```c
auto_shift: auto_shift {
    compatible = "zmk,behavior-hold-tap";
    #binding-cells = <2>;
    tapping-term-ms = <50>;    // Very fast tap-hold threshold
    bindings = <&mt>, <&kp>;
};
```

**Creative Use:** Nesting behaviors (`&mt` inside hold-tap) for complex interactions.

---

## Quick Reference Tables

### Common Timing Values

| Parameter | Conservative | Balanced | Aggressive |
|-----------|-------------|----------|------------|
| tapping-term-ms | 300 | 200-280 | 150 |
| quick-tap-ms | 200 | 125-175 | 100 |
| require-prior-idle-ms | 200 | 150 | 100 |
| combo timeout-ms | 75 | 50 | 30 |

### Layer Activation Behaviors

| Need | Behavior | Example |
|------|----------|---------|
| Hold for layer | `&mo` | `&mo 1` |
| Hold for layer, tap for key | `&lt` | `&lt 1 SPACE` |
| Toggle layer on/off | `&tog` | `&tog 2` |
| Next keypress only | `&sl` | `&sl 1` |
| Switch to layer | `&to` | `&to 3` |

### Modifier Shortcuts

| Modifier | Code | Position (GACS) |
|----------|------|-----------------|
| Shift | `LSHIFT`/`RSHIFT` | Index finger |
| Control | `LCTRL`/`RCTRL` | Middle finger |
| Alt | `LALT`/`RALT` | Ring finger |
| GUI | `LGUI`/`RGUI` | Pinky finger |

---

## Additional Resources

- **ZMK Documentation**: https://zmk.dev/docs
- **Miryoku GitHub**: https://github.com/manna-harbour/miryoku
- **Miryoku ZMK**: https://github.com/manna-harbour/miryoku_zmk
- **ZMK Discord**: Active community for troubleshooting
- **Keyboard Layout Editor**: http://www.keyboard-layout-editor.com/

---

## Tips for Keymap Development

1. **Start simple**: Begin with basic layers, add complexity gradually
2. **Test timing**: Adjust hold-tap timings to match your typing speed
3. **Use combos wisely**: Place on comfortable, memorable positions
4. **Mirror layouts**: Symmetric designs reduce cognitive load
5. **Iterate**: Keymaps evolve with use - don't aim for perfection immediately
6. **Document**: Comment your keymap with `//` to remember design decisions
7. **Version control**: Use git to track changes and revert experiments

---

*This reference consolidates research from ZMK official documentation, Miryoku project, and community best practices. Last updated: 2025-09-30*
