import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract mfiincone is Ownable {
    //--------------------------- EVENT --------------------------
    /*
    MFI存款事件
    传入 用户地址,存款数量,区块跨度
    */
    event MFIDeposit(address userAddr, uint256 count, uint256 time);

    /*
    MFI取款事件
    传入 用户地址,取款数量,当前区块号
    */
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time);

    /*
    MFI退款事件
    传入 用户地址,退款数量,当前区块号
    */
    event MFIDropOut(address userAddr, uint256 count, uint256 time);

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    //MFI地址
    ERC20 public MfiAddress;
    //Mfi总数
    uint256 public MFICount;
    //存款数量(默认500个)
    uint256 public DepositCount = 500e18;

    //--------------------------- STRUCT --------------------------
    struct userCount {
        uint256 userDepositCount;
        uint256 userWithdrawalCount;
        uint256 time;
    }

    //--------------------------- MAPPING --------------------------
    mapping(address => userCount) userData;


    //---------------------------ADMINISTRATOR FUNCTION --------------------------
    /*
    设置MFI地址
    传入 mfi地址
    */
    function SetMfiAddress(ERC20 _mfiAddress) external onlyOwner {
        MfiAddress = _mfiAddress;
    }

    /*
    设置用户奖励总数
    传入 用户数组,奖励数组
    */
    function SetUserRewardCount(address[] memory _userAddres, uint256[] memory _userCounts) external onlyOwner {
        for (uint256 i = 0; i < _userAddres.length; i++) {
            userData[_userAddres[i]].userWithdrawalCount = _userCounts[i];
        }
    }

    /*
    设置存款数量
    传入 存款数量
    */
    function SetDepositCount(uint256 _depositCount) external onlyOwner {
        DepositCount = _depositCount;
    }

    /*
    借用token
    传入 用户地址,数量
    */
    function borrow(address _userAddr, uint256 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    //---------------------------INQUIRE FUNCTION --------------------------
    /*
    查看MFI用户余额
    返回 mfi数量
    */
    function GetUserBalance() public view returns (uint256){
        return MfiAddress.balanceOf(msg.sender);
    }

    /*
    查看用户质押总数
    返回 用户质押mfi总数
    */
    function GetUserWithdrawalCount() public view returns (uint256){
        return userData[msg.sender].userWithdrawalCount;
    }

    /*
    查看用户奖励总数
    返回 用户奖励总数
    */
    function GetUserDepositCount() public view returns (uint256){
        return userData[msg.sender].userDepositCount;
    }

    //--------------------------- USER FUNCTION --------------------------
    /*
    存款
    传入 存款数量
    */
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

    /*
    退款
    */
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

    /*
    取款
    传入 取款数量
    */
    function withdrawal(uint256 _count) external {
        require(GetUserWithdrawalCount() >= _count, "Insufficient amount of withdrawals:(");
        MfiAddress.safeTransfer(msg.sender, _count);
        (, userData[msg.sender].userWithdrawalCount) = userData[msg.sender].userWithdrawalCount.trySub(_count);
        emit MFIWithdrawal(msg.sender, _count, block.number);
    }
}
