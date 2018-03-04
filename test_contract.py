#import 
import ethereum.config as config
from ethereum.tools import tester
from ethereum import utils
from ethereum.tools._solidity import (
    get_solidity,
    compile_file,
    solidity_get_contract_data
    )
SOLIDITY_AVAILABLE = get_solidity() is not None

def sha256(s):
    import hashlib
    return hashlib.sha256(s).digest()

env = config.Env()
#env.config['BLOCK_GAS_LIMIT'] = 3141592000
#env.config['START_GAS_LIMIT'] = 3141592000
s = tester.Chain(env = env)
s.mine()

contract_path = './rock_paper_scissors.sol'
contract_name = 'RockPaperScissors'
contract_compiled = compile_file(contract_path)

contract_data = solidity_get_contract_data(
    contract_compiled,
    contract_path,
    contract_name,)

contract_address = s.contract(contract_data['bin'], language='evm')

contract_abi = tester.ABIContract(
    s,
    contract_data['abi'],
    contract_address)
