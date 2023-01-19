pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../interfaces/IOtpOracle.sol";
import "../interfaces/IOtpOracle1.sol";

contract TestOracle is ERC20, ERC20Burnable {
    address public deployer;

    IOtpOracle1 public otpOracle;

    constructor(
        string memory _name,
        string memory _symbol,
        address _otpOracle
    ) ERC20(_name, _symbol) {
        deployer = msg.sender;
        otpOracle = IOtpOracle1(_otpOracle);
    }

    function mint(address _account, uint256 _amount) public {
        _mint(_account, _amount);
    }

    function createOtp(string memory _benId, uint256 _amount) public {
        bytes32 benId = keccak256(abi.encodePacked(_benId));
        bytes memory callBackData = abi.encodeWithSignature(
            "mint(address,uint256)",
            address(this),
            1000
        );
        //otpOracle.createRequest(address(this), benId, _amount, callBackData);
    }
}
