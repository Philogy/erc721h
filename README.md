# ERC721H

Gas optimized version of [ERC721A](https://github.com/chiru-labs/ERC721a) in
Huff.

## Naming Convention
- prefix all macros, constants and labels with `{FileName}__` e.g. `ERC721H__MY_MACRO`
- exceptions to above rule
  - prefix storage slot constants with `{FileName}_SLOT__`
  - name the constructor and selector switch `{FileName}_CONSTRUCTOR` and `{FileName}_SELECTOR_SWITCH` respectively
  - function signature constants do not require a prefix
- prefix macros, labels and constants that are only meant for internal use (quasi
  private) with a double underscore e.g. `__ERC721H__selectorSwitchEnd`
- use camel case for labels, custom function signatures
- use snake case for macros / constants
