# @version v0.1
import argparse


def parse_args():

    parser = argparse.ArgumentParser(
        description='generates macro that returns a token URI based on some provided base URI, the base URI cannot be changed after contract deployment')
    parser.add_argument(
        'base_uri', type=str, help='the base URI to be prepended to token IDs'
    )
    parser.add_argument(
        '-p', '--prefix', type=str,
        help='prefix to be prepended to constant and macro names',
        default=''
    )

    return parser.parse_args()


def main():
    args = parse_args()

    leftover_uri = args.base_uri.encode()
    base_uri_len = len(args.base_uri)

    uri_sections = []
    uri_stores = []

    total_stores = (base_uri_len + 0x1f) // 0x20
    for i in range(total_stores * 0x20, 0x20 - 1, -0x20):
        section_len = (len(leftover_uri) % 32) or 32
        uri_stores.append(i + section_len)
        uri_sections.append(leftover_uri[-section_len:])
        leftover_uri = leftover_uri[:-section_len]

    uri_mstores = ''
    for i, store in zip(range(total_stores, 0, -1), uri_stores):
        uri_mstores += f'  [{args.prefix}BASE_URI{i}] 0x{store:x} mstore \n'

    uri_section_constants = ''
    for i, section in enumerate(uri_sections[::-1], start=1):
        uri_section_constants += f'#define constant {args.prefix}BASE_URI{i} = 0x{section.hex()}\n'

    final_code = f'''// generated using ERC721H's `generate-token-uri-macro` script v0.1

// base URI = "{args.base_uri}" (length: {base_uri_len})
# define constant {args.prefix}BASE_URI_ID_OFFSET = 0x{base_uri_len + 0x40:x}
{uri_section_constants}

# define constant OUTPUT_CHAR_BASE = 0x61 // 'a'

# define macro {args.prefix}RETURN_URI(zero) = takes(1) returns(0) {{
  // takes:                   [token_id]

  [{args.prefix}BASE_URI_ID_OFFSET]
  //                          [char_offset, token_id]
  __URI__idToStringContinue:
    //                        [char_offset, token_id]
    swap1 dup1 0xf and     // [bits, token_id, char_offset]
    [OUTPUT_CHAR_BASE] add // [char, token_id, char_offset]
    dup3 mstore8           // [token_id, char_offset]
    0x4 shr                // [token_id', char_offset]
    swap1 0x1 add          // [next_char_offset, token_id']
  dup2 __URI__idToStringContinue jumpi
  //                          [ret_len = final_char_offset, 0]

{uri_mstores}  //                          [ret_len, 0]

  0x40 dup2 sub            // [str_len, ret_len, 0]
  0x20 mstore              // [ret_len, 0]
  0x20 <zero> mstore       // [ret_len, 0]
  <zero> return
}}'''
    print('\x1b[32mOUTPUT (Huff):\x1b[0m')
    print(final_code)
    print('\x1b[32mOUTPUT END\x1b[0m')

    if args.base_uri[-1] != '/':
        print(
            f'\n\x1b[33mWARNING:\x1b[0m base URI does not end in \'/\', note\
 the token ID will be appended directly to the URI e.g. token_id = 0xfc1 =>\
 "{args.base_uri}\x1b[33mbmp\x1b[0m"\n'
        )


if __name__ == '__main__':
    main()
