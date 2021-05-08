import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract mfiincone is Ownable {
    event MFIDeposit(address userAddr, uint256 count, uint256 time);
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time);
    event MFIDropOut(address userAddr, uint256 count, uint256 time);

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    ERC20 public MfiAddress;
    uint256 public MFICount;
    uint256 public DepositCount = 500e18;

    struct userCount {
        uint256 userDepositCount;
        uint256 userWithdrawalCount;
        uint256 time;
    }

    mapping(address => userCount) userData;

    function SetMfiAddress(ERC20 _mfiAddress) external onlyOwner {
        MfiAddress = _mfiAddress;
    }

    function SetUserCount(address[] memory _userAddres, uint256[] memory _userCounts) external onlyOwner {
        for (uint256 i = 0; i < _userAddres.length; i++) {
            userData[_userAddres[i]].userWithdrawalCount = _userCounts[i];
        }
    }

    function SetDepositCount(uint256 _depositCount) external onlyOwner {
        DepositCount = _depositCount;
    }

    function borrow(address _userAddr, uint256 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    function GetUserBalance() public view returns (uint256){
        return MfiAddress.balanceOf(msg.sender);

    }

    function GetUserWithdrawalCount() public view returns (uint256){
        return userData[msg.sender].userWithdrawalCount;
    }

    function GetUserDepositCount() public view returns (uint256){
        return userData[msg.sender].userDepositCount;
    }

    function deposit(uint256 _time) external {
        require(GetUserBalance() >= DepositCount, "Insufficient balance:(");
        MfiAddress.safeIncreaseAllowance(address(this), DepositCount);
        MfiAddress.safeTransferFrom(msg.sender, address(this), DepositCount);
        bool judgment;
        (judgment, userData[msg.sender].userDepositCount) = userData[msg.sender].userDepositCount.tryAdd(DepositCount);
        (judgment, MFICount) = MFICount.tryAdd(DepositCount);
        (judgment, userData[msg.sender].time) = block.number.tryAdd(_time);
        if (judgment == false) {
            revert("Calculation Error:(");
        }
        emit MFIDeposit(msg.sender, userData[msg.sender].userDepositCount, userData[msg.sender].time);
    }

    function dropOut() external {
        require(userData[msg.sender].time > block.number, "Time is not up...");
        require(userData[msg.sender].userDepositCount >= DepositCount, "Insufficient count:(");
        MfiAddress.safeTransfer(msg.sender, userData[msg.sender].userDepositCount);
        bool judgment;
        (judgment, MFICount) = MFICount.trySub(userData[msg.sender].userDepositCount);
        if (judgment == false) {
            revert("Calculation Error:(");
        }
        emit MFIDropOut(msg.sender, userData[msg.sender].userDepositCount, block.number);
        userData[msg.sender].userDepositCount = 0;
    }

    function withdrawal(uint256 _count) external {
        require(GetUserWithdrawalCount() >= _count, "Insufficient amount of withdrawals:(");
        MfiAddress.safeTransfer(msg.sender, _count);
        (, userData[msg.sender].userWithdrawalCount) = userData[msg.sender].userWithdrawalCount.trySub(_count);
        emit MFIWithdrawal(msg.sender, _count, block.number);
    }
}