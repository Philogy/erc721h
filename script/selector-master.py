from eth_utils.abi import function_signature_to_4byte_selector
from eth_utils.crypto import keccak
from math import ceil, log2
import pyperclip


def find_reselector_nonce(selectors, mask):
    for nonce in range(1 << 256):
        nb = nonce.to_bytes(32, 'big')
        hashes = {}
        for selector in selectors:
            out_hash = keccak(selector.to_bytes(4, 'big') + nb + b'\0'*28)
            hashes[selector] = int.from_bytes(out_hash, 'big')

        # with mask
        masked_ids = {}
        for selector, h in hashes.items():
            masked_id = h & mask
            if masked_id in masked_ids:
                break
            masked_ids[masked_id] = selector
        else:
            return nonce, masked_ids

    # will never actually be reached, appeases linter
    return None, {}


def print_selector_map(selector_map, bits, selector_to_name, shift=0):
    for sub_id in range(1 << bits):
        selector_base = selector_map.get(sub_id << shift)
        selector = None if selector_base is None else f'0x{selector_base:08x}'
        name = selector_to_name.get(selector_base)
        print(f'selector({sub_id}) -> {selector} ({name})')


def create_jump_table(selector_map, bits, selector_to_name, empty_label, shift=0):
    def get_label(i):
        selector = selector_map.get(i << shift)
        if selector is None:
            return empty_label
        return selector_to_name[selector]
    labels = ' '.join(map(get_label, range(1 << bits)))
    return f'''#define jumptable__packed FN_TABLE {{
  {labels}
}}'''


def create_jump_dests(selector_to_name, empty_label, collision_detection):
    jump_dests = ''
    if collision_detection:
        for selector, name in selector_to_name.items():
            jump_dests += f'''
  {name}:
    dup1 {hex(selector)} sub {empty_label} jumpi'''
    else:
        for name in selector_to_name.values():
            jump_dests += f'\n  {name}:'

    jump_dests += f'\n  {empty_label}:'
    return jump_dests


def main(functions, empty_label, collision_detection=True):
    selector_to_name = {}
    selectors = set()

    for name, fn in functions.items():
        selector = int.from_bytes(
            function_signature_to_4byte_selector(fn),
            'big'
        )
        selectors.add(selector)
        print(f'0x{selector:08x} ({name})')
        selector_to_name[selector] = name

    bits = int(ceil(log2(len(functions))))
    mask = (1 << bits) - 1

    basic_offset = None
    for i in range(32 - bits + 1):
        masked_ids = set()
        for selector in selectors:
            masked_id = (selector >> i) & mask
            if masked_id in masked_ids:
                break
            masked_ids.add(masked_id)
        else:
            basic_offset = i
            break

    print('')
    offset_mask = mask << 1
    jump_dests = create_jump_dests(
        selector_to_name,
        empty_label,
        collision_detection
    )
    if basic_offset is not None:
        print('nonce (basic offset):', basic_offset)
        print('op: BASIC')
        id_to_selector = {}
        for selector in selectors:
            id_to_selector[(selector >> basic_offset) & mask] = selector
        print_selector_map(id_to_selector, bits, selector_to_name)
        jump_table = create_jump_table(
            id_to_selector,
            bits,
            selector_to_name,
            empty_label
        )
        total_shift = basic_offset + 223
        code = f'''{jump_table}

#define macro _MAIN(zero) = takes(0) returns (0) {{
  <zero> calldataload // [cd[0]]
  0x2                 // [2, cd[0]]
  // -- get function index from selector
  dup2                // [cd[0], 2, cd[0]]
  {hex(total_shift)} shr {hex(offset_mask)} and   // [fn_index << 1, 2, cd[0]]
  // -- load jump label
  __tablestart(FN_TABLE) add
  0x1e codecopy       // [cd[0]]
  0xe8 shr            // [selector]
  <zero> mload        // [jump_loc, selector]
  // -- use jump label
  jump
{jump_dests}
}}

#define macro MAIN() = takes(0) returns(0) {{
  _MAIN(returndatasize)
}}
'''

    else:
        nonce, selector_map = find_reselector_nonce(selectors, offset_mask)
        assert nonce is not None
        print('nonce:', hex(nonce))
        print_selector_map(selector_map, bits, selector_to_name, shift=1)
        jump_table = create_jump_table(
            selector_map,
            bits,
            selector_to_name,
            empty_label,
            1
        )
        code = f'''{jump_table}

#define macro _MAIN(zero) = takes(0) returns(0) {{
  <zero> calldataload // [cd[0]]
  // -- store selector
  dup1 msize mstore   // [cd[0]]
  // -- store nonce (also clears non-selector calldata)
  {hex(nonce)} 0x4 mstore
  // jump label size
  0x2                 // [2, cd[0]]
  // -- get function index
  msize <zero> sha3 {hex(offset_mask)} and
  //                     [function_index << 1, 2, cd[0]]
  // -- load jump label
  __tablestart(FN_TABLE) add
  0x5e codecopy       // [cd[0]]
  0xe8 shr            // [selector]
  0x40 mload          // [jump_loc, selector]
  // -- use jump label
  jump
{jump_dests}
}}

#define macro MAIN() = takes(0) returns(0) {{
  _MAIN(returndatasize)
}}
'''
    print('\nHuff code:\n=====================\n\n')
    print(code)
    pyperclip.copy(code)


def sig_to_label(sig):
    return sig.split('(', 1)[0]


if __name__ == '__main__':
    sigs = [
        # metadata
        'name()',
        'symbol()',
        'decimals()',
        # global
        'totalSupply()',
        # transfer related
        'transferFrom(address,address,uint256)',
        'transfer(address, uint256)',
        'balanceOf(address)',
        # approval
        'approve(address,uint256)',
        'allowance(address, address)',
        # deposit
        'deposit()',
        'depositTo(address)',
        'depositAmountTo(address, uint256)',
        'depositAmount(uint256)',
        # withdraw
        'withdraw(uint256)',
        'withdrawTo(address, uint256)',
        'withdrawFrom(address, uint256)',
        'withdrawFromTo(address, address uint256)',
        # permit
        'DOMAIN_SEPARATOR()',
        'nonces(address)',
        'permit(address, address, uint256, uint256, uint8, bytes32, bytes32)',
        # utility
        'multicall(bytes[])'
    ]

    labeled = {
        sig_to_label(sig): sig
        for sig in sigs
    }

    main(labeled, 'no_selector_match', collision_detection=True)
