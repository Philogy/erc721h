# ERC721H

Gas optimized version of [ERC721A](https://github.com/chiru-labs/ERC721a) in
Huff.

## Naming Convention
- prefix all macros / constants / labels with `{FileName}__` e.g. `ERC721H__MY_MACRO`
- exceptions to above rule
  - prefix storage slot constants with `{FileName}_SLOT__`
  - name the constructor and selector switch `{FileName}_CONSTRUCTOR` / `{FileName}_SELECTOR_SWITCH` respectively
  - function signature constants do not require a prefix
- prefix macros / labels / constants that are only meant for internal use (quasi
  private) with a double underscore e.g. `__ERC721H__selectorSwitchEnd`
- use camel case for labels / custom function signatures
- use snake case for macros / constants

## Using ERC721H
### Using ERC721H - Security Considerations
- Excessively large, arbitrary `ERC721H__START_TOKEN_ID` values may lead to
  owner data storage slots colliding with other variables, leading to a suite of
  bugs / vulnerabilities

## Progress

### Progress - method implementation
- [x] internal `name()` connection
- [x] internal `symbol()` connection
- [x] internal `tokenURI(uint256)` connection
- [x] internal `supportsInterface(bytes4)` connection

- [x] public `totalSupply()`
- [x] public `transferFrom(address, address, uint256)`
- [x] public `safeTransferFrom(address, address, uint256)`
- [x] public `safeTransferFrom(address, address, uint256, bytes)`
- [x] public `getApproved(uint256)`
- [x] public `isApprovedForAll(address, address)`
- [x] public `approve(address, uint256)`
- [x] public `setApprovalForAll(address, bool)`
- [x] public `ownerOf(uint256)`
- [x] public `balanceOf(address)`

- [x] internal (no receive check) mint macro: `ERC721H__MINT`
- [x] internal safe mint (with receive check) macro: `ERC721H__SAFE_MINT`
- [x] internal transfer (no receive check) macro: `ERC721H__TRANSFER`
- [x] internal direct burn macro (doesn't check if token exists): `ERC721H__DIRECT_BURN`
- [x] internal "safe" burn macro (checks token existance): `ERC721H__FULL_BURN`
- [x] internal default supportsInterface macro: `ERC721H__SUPPORTS_INTERFACE`

### Progress - testing
TODO
