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

## Gas Comparison
|                      Tests|    Huff|        OZ| OZ (delta)|   Azuki|Azuki (delta)|
|---------------------------|--------|----------|-----------|--------|-------------|
|                   Mint 200| 437,232| 4,999,553| -4,562,321| 447,020|       -9,788|
|                    Mint 50| 149,382| 1,273,403| -1,124,021| 152,120|       -2,738|
|  Safe Transfer To Receiver|  63,550|    66,160|     -2,610|  65,436|       -1,886|
|           Simple Burn 1 In|  60,503|    38,893|    +21,610|  82,611|      -22,108|
|                Simple Burn|  38,342|    38,893|       -551|  60,214|      -21,872|
|Simple Safe Transfer To EOA|  62,379|    64,151|     -1,772|  63,364|         -985|
|       Simple Transfer 1 In|  81,987|    61,271|    +20,716|  82,958|         -971|
|      Simple Transfer 20 In| 115,306|    61,271|    +54,035| 119,835|       -4,529|
|            Simple Transfer|  59,817|    61,271|     -1,454|  60,561|         -744|

### Gas Comparison - Methodology
**General Approach:**
1. Create minimal reference implementations using the ERC721A and OpenZeppelin libraries respectively, viewable under `src/refs/`.
2. Created comparison test contract with identical tests for all 3 versions `test/CompareERC721.t.sol`
3. Wrote and ran script that extracts the gas use of the actual main call in each test and adds the 21k base transaction stipend to the total cost of all calls

**Table Generation:**
To generate the above table run the following commands
```bash
forge build // necessary to ensure no warnings in `forge test` output
forge test --match-contract CompareERC721Test --ffi -vvvv > gas-compare.txt
python script/extract_gas_cost_comparison.py
```
