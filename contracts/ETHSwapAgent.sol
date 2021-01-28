pragma solidity 0.6.4;

import "./interfaces/IERC20.sol";
import "openzeppelin-solidity/contracts/proxy/Initializable.sol";
import "openzeppelin-solidity/contracts/GSN/Context.sol";

contract  ETHSwapAgent is Context, Initializable {
    mapping(address => bool) public registeredERC20;
    address payable private _owner;
    uint256 private _swapFee;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SwapPairRegister(address indexed contractAddr, string name, string symbol, uint8 decimals);
    event SwapStarted(address indexed erc20Addr, address indexed fromAddr, uint256 amount, uint256 feeAmount);
    event SwapFilled(address indexed erc20Addr, bytes32 indexed bscTxHash, address indexed toAddress, uint256 amount);

    constructor() public {
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function initialize(uint256 swapFee, address payable owner) public initializer {
        _swapFee = swapFee;
        _owner = owner;
    }

    /**
        * @dev Leaves the contract without owner. It will not be possible to call
        * `onlyOwner` functions anymore. Can only be called by the current owner.
        *
        * NOTE: Renouncing ownership will leave the contract without an owner,
        * thereby removing any functionality that is only available to the owner.
        */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function owner() external view returns (address) {
        return _owner;
    }

    /**
     * @dev Returns minimum swap fee from ERC20 to BEP20
     */
    function swapFee() external view returns (uint256) {
        return _swapFee;
    }

    /**
     * @dev Returns set minimum swap fee from ERC20 to BEP20
     */
    function setSwapFee(uint256 swapFee) onlyOwner external {
        _swapFee = swapFee;
    }

    function registerSwapToBSC(address erc20Addr) external returns (bool) {
        require(!registeredERC20[erc20Addr], "already registered");

        string memory name = IERC20(erc20Addr).name();
        string memory symbol = IERC20(erc20Addr).symbol();
        uint8 decimals = IERC20(erc20Addr).decimals();
        //TODO add checks
        registeredERC20[erc20Addr] = true;

        emit SwapPairRegister(erc20Addr, name, symbol, decimals);
        return true;
    }

    function fillBSC2ETHSwap(bytes32 bscTxHash, address erc20Addr, address toAddress, uint256 amount) onlyOwner external returns (bool) {
        IERC20(erc20Addr).transfer(toAddress, amount);  //TODO change to safeTransfer
        emit SwapFilled(erc20Addr, bscTxHash, toAddress, amount);
        return true;
    }

    function swapETH2BSC(address erc20Addr, uint256 amount) payable external returns (bool) {
        require(registeredERC20[erc20Addr], "not registered token");
        require(msg.value >= _swapFee, "swap fee is not enough");

        IERC20(erc20Addr).transferFrom(msg.sender, address(this), amount); //TODO change to safeTransferFrom
        if (msg.value != 0) {
            _owner.transfer(msg.value);
        }

        emit SwapStarted(erc20Addr, msg.sender, amount, msg.value);
        return true;
    }
}