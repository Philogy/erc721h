const { ethers } = require('ethers')

const createMask = (totalSigs) => {
  const bits = Math.ceil(Math.log(totalSigs) / Math.log(2))
  const mask = (1 << bits) - 1
  return [mask, bits]
}

const testShiftOnSigs = (sigs, mask, shift) => {
  const subSigs = new Set()
  sigs.forEach((sig) => subSigs.add((sig >> shift) & mask))
  return subSigs.size === sigs.length
}

const tryFindUsefulShift = (sigs) => {
  const totalFunctions = sigs.length
  const [mask, bits] = createMask(totalFunctions)

  // 32 (total bits in a selector) - mask bit size + 1
  for (let shift = 0; shift < 33 - bits; shift++) {
    if (testShiftOnSigs(sigs, mask, shift)) return [shift, mask, bits]
  }
  return [null, null, null]
}

async function main() {
  const nft = new ethers.utils.Interface([
    'function name()',
    'function symbol()',
    'function tokenURI(uint256)',
    'function approve(address,uint256)',
    'function safeTransferFrom(address,address,uint256)',
    'function safeTransferFrom(address,address,uint256,bytes)',
    'function setApprovalForAll(address,bool)',
    'function transferFrom(address,address,uint256)',
    'function balanceOf(address)',
    'function getApproved(uint256)',
    'function isApprovedForAll(address,address)',
    'function ownerOf(uint256)',
    'function supportsInterface(bytes4)',
  ])
  const functionArr = Array.from(Object.keys(nft.functions))
  console.log('functionArr: ', functionArr)

  const getNumSighash = (fn) => parseInt(nft.getSighash(fn), 16)
  const sigs = functionArr.map(getNumSighash)

  const [usefulShift, mask, bits] = tryFindUsefulShift(sigs)
  console.log('usefulShift: ', usefulShift)
  console.log(`mask: 0x${mask.toString(16)}`)
  console.log('bits: ', bits)
  console.log(`total functions: ${sigs.length}`)

  const getBits = (fn) => (getNumSighash(fn) >> usefulShift) & mask

  if (usefulShift !== null) {
    const fns = {}
    functionArr
      .sort((a, b) => getBits(a) - getBits(b))
      .forEach((fn) => {
        fns[getBits(fn)] = fn
      })
    for (let i = 0; i < 1 << bits; i++) {
      const fn = fns[i]
      const fnAsStr = fn !== undefined ? `${fn} [${nft.getSighash(fn)}]` : '-'
      console.log(`{${i.toString(2).padStart(bits, '0')}} ${fnAsStr}`)
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('err:', err)
    process.exit(1)
  })
