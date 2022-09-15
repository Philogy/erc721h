import re
import pandas as pd
from collections import defaultdict

def clean_str_arr(arr):
    return list(map(str.strip, arr))


def parse_test_name(raw_name):
    relevant_section = raw_name[4:-2]  # remove 'test' and '()'
    words = ['']
    for c in relevant_section:
        if c.isupper():
            if words[-1].isupper():
                words[-1] += c
            else:
                words.append(c)
        elif c.isdigit() != words[-1].isdigit():
            words.append(c)
        else:
            words[-1] += c
    return ' '.join(words[:-1]).strip(), words[-1]

def parse_test_output(test):
    header = test[0]
    name, category = parse_test_name(header.split()[1])
    rows = test[1:]
    call_gas_amount_matches = [
        re.search(r'\[(\d+)\]', row)
        for row in rows
    ]
    call_gas_amounts = [
        int(m.group(1))
        for m in call_gas_amount_matches 
        if m is not None
    ]
    print('name:', repr(name))
    return name, category, list(filter(None, call_gas_amounts))[1] + 21000
    

def main():
    with open('gas-compare.txt', 'r') as f:
        raw_gas_data = f.read()
    lines = clean_str_arr(raw_gas_data.splitlines())[3:-1]
    tests = [[]]
    for row in lines:
        if row == '':
            tests.append([])
        else:
            tests[-1].append(row)
    tests = list(filter(None, tests))
    gas_data = list(map(parse_test_output, tests))

    tests = defaultdict(list)

    for name, contract_type, gas in gas_data:
        tests[name].append((contract_type, gas))

    contract_types = {
        'Tests': [],
        'Huff': [],
        'OZ': [],
        'OZ (delta)': [],
        'Azuki': [],
        'Azuki (delta)': []
    }

    for test, individual_tests in tests.items():
        contract_types['Tests'].append(test)
        for contract_type, gas in individual_tests:
            contract_types[contract_type].append(gas)

    for huff, oz, azuki in zip(contract_types['Huff'], contract_types['OZ'], contract_types['Azuki']):
        contract_types['OZ (delta)'].append(huff - oz)
        contract_types['Azuki (delta)'].append(huff - azuki)

    for col, col_values in contract_types.items():
        if col == 'Tests': continue
        contract_types[col] = [('+' if val > 0 and 'delta' in col else '') + f'{val:,}' for val in col_values]
    
    print(pd.DataFrame(data=contract_types))



if __name__ == '__main__':
    main()
