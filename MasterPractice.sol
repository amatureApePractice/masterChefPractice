pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SushiToken.sol";

interface IMigratorChef {
    //Perform LP token migration from legacy UniswapV2 to SushiSwap.
    //Take the current LP token address and return the new LP token address.
    //Migrator should have full access to the caller's LP token.
    //Return the new LP token address.
    //
    // XXX Migrator must have allowance access to UniswapV2 LP tokens.
    // SushiSwap must min EXACTLY the same amount of SushiSwap LP tokens or
    // else something bad will happen. Traditional UniswapV2 does not
    // do that so be careful!
    function migrate(IERC20 token) external returns (IERC20);
}

// MasterChef is the master of Sushi. He can make Sushi and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once SUSHI is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; //Reward debt. See explanation below.
        //
        //We do some fancy math here. Basically, any point in time, the amount of SUSHIs
        // entitled to a user but is pending to be distributed is:
        //
        // pending reward = (user.amount * pool.accSushiPerShare) - user.rewardDebt
        //
        //Whenver a user deposits or withdraws LP tokens to a pool. Here's what happens:
        // 1. The pool's `accSushiPerShare` (and `lastRewardBlock`) gets updated.
        // 2. User receives the pending reward sent to his/her address.
        // 3. User's `amount` gets updated.
        // 4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
      IERC20 lpToken; // Address of LP token contract.
      uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
      uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
      uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12. See below.
    }

    // The SUSHI TOKEN!
    SushiToken public sushi;

    //Dev address.
    address public devaddr;

    //Block number when bonus SUSHI period ends.
    uint256 public bonusEndBlock;

    // SUSHI tokens created per block
    uint256 public sushiPerBlock;

    //Bonus multipler for early sushi makers.
    uint256 public constant BONUS_MULTIPLIER = 10;

    // The migrator contract. It has a lot of power. Can only be set through governance (owner).
    IMigratorChef public migrator;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    //Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    //Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPOint = 0;

    // The block number when SUSHI mining start
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount)

    constructor(
      SushiToken _sushi,
      address _devaddr,
      uint256 _sushiPerBlock,
      uint256 _startBlock,
      uint256 _bonusEndBlock
    ) public {
      sushi = _sushi;
      devaddr = _devaddr;
      sushiPerBlock = _sushiPerBlock;
      bonsuEndBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
      return poolInfo.length;
    }

    //Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPOint, IERC20 _lpToken, bool _withdrawUpdate) public onlyOwner {
      if (_withUpdate) {
        massUpdatePools();
      }
      uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
      totalAllocPoint = totalAllocPoint.add(_allocPoint);
      poolInfo.push(poolInfo({
        lpToken: _lpToken,
        allocPoint: _allocPoint,
        lastRewardBlock: lastRewardBlock,
        accSushiPerShare: 0
      }));
    }
;}
