# ERC721H

Most optimized batch minting ERC721 implementation in the EVM ecosystem. Rewrite
of [ERC721A](https://github.com/chiru-labs/ERC721a) in Huff.


## Gas Comparison (ERC721H vs ERC721A vs OpenZeppelin's ERC721)
|                      Tests|    Huff|   Azuki|Azuki (delta vs. Huff)|        OZ| OZ (delta vs. Huff)|
|---------------------------|--------|--------|-------------|----------|-----------|
|                   Mint 200| 437,232| 447,020|       -9,788| 4,999,553| -4,562,321|
|                    Mint 50| 149,382| 152,120|       -2,738| 1,273,403| -1,124,021|
|  Safe Transfer To Receiver|  63,550|  65,436|       -1,886|    66,160|     -2,610|
|           Simple Burn 1 In|  60,503|  82,611|      -22,108|    38,893|    +21,610|
|                Simple Burn|  38,342|  60,214|      -21,872|    38,893|       -551|
|Simple Safe Transfer To EOA|  62,379|  63,364|         -985|    64,151|     -1,772|
|       Simple Transfer 1 In|  81,987|  82,958|         -971|    61,271|    +20,716|
|      Simple Transfer 20 In| 115,306| 119,835|       -4,529|    61,271|    +54,035|
|            Simple Transfer|  59,817|  60,561|         -744|    61,271|     -1,454|

### Gas Comparison - Methodology
**General Approach:**

1. Create minimal reference implementations using the ERC721A and OpenZeppelin libraries respectively, viewable under [`src/refs/`](src/refs)
2. Created comparison test contract with identical tests for all 3 versions [`test/CompareERC721.t.sol`](test/CompareERC721.t.sol)
3. Wrote and ran script that extracts the gas use of the actual main call in each test and adds the 21k base transaction stipend to the total cost of all calls

**Table Generation:**

To generate the above table run the following commands
```bash
forge build # necessary to ensure no warnings in `forge test` output
forge test --match-contract CompareERC721Test --ffi -vvvv > gas-compare.txt
python script/extract_gas_cost_comparison.py
```

## Using ERC721H
### Using ERC721H - Security Considerations
- Excessively large, arbitrary `ERC721H__START_TOKEN_ID` values may lead to
  owner data storage slots colliding with other variables, leading to a suite of
  bugs / vulnerabilities

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
