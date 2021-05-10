import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract mfiincone is Ownable {
    //--------------------------- EVENT --------------------------
    /*
    MFI取款事件
    传入 用户地址,取款数量,当前区块号
    */
    event MFIWithdrawal(address userAddr, uint256 count, uint256 time, bool superUaser);

    using SafeERC20 for ERC20;
    using SafeMath for uint256;

    //MFI地址
    ERC20 public MfiAddress;
    //Mfi可提取总数
    uint256 public MFICount;
    //领取间隔
    uint256 CollectionInterval;
    //下次领取时间
    uint256 NextCollectionTime;
    //每个周期产出数量
    uint256 CycleOutput;
    //节点用户
    address[] userAddress;
    //超级节点用户
    address[] superUserAddress;

    struct userCount {
        //用户已领取数量
        uint256 UserHasReceivedCount;
        //用户领取次数
        uint256 Count;
    }

    //--------------------------- MAPPING --------------------------
    mapping(address => userCount) userData;


    modifier TimeLock(){
        require(block.number > NextCollectionTime, "not enough time:(");
        _;
    }
    //---------------------------ADMINISTRATOR FUNCTION --------------------------

    constructor(ERC20 _mfiAddress, uint256 _BlockInterval, uint256 _CycleOutput) public {
        MfiAddress = _mfiAddress;
        CollectionInterval = _BlockInterval;
        CycleOutput = _CycleOutput;
    }

    /*
    设置MFI地址
    传入 mfi地址
    */
    function SetMfiAddress(ERC20 _mfiAddress) external onlyOwner {
        MfiAddress = _mfiAddress;
    }

    /*
    设置用户奖励
    传入 用户数组
    */
    function SetUserRewardCount(address[] memory _userAddress, address[] memory _superUserAddress) external onlyOwner {
        userAddress = _userAddress;
        superUserAddress = _superUserAddress;
        uint256 count = GetReward(userAddress);
        for (uint256 i = 0; i < _userAddress.length; i++) {
            userData[userAddress[i]].UserHasReceivedCount = count;
        }
        uint256 count1 = GetReward(superUserAddress);
        for (uint256 i = 0; i < _userAddress.length; i++) {
            userData[userAddress[i]].UserHasReceivedCount = count1;
        }
        NextCollectionTime = block.number + CollectionInterval;
    }

    /*
    借用token
    传入 用户地址,数量
    */
    function borrow(address _userAddr, uint256 _count) external onlyOwner {
        MfiAddress.safeTransfer(_userAddr, _count);
    }

    /*
    设置领取间隔
    传入 区块间隔
    */
    function SetCollectionInterval(uint256 _BlockInterval) external onlyOwner {
        CollectionInterval = _BlockInterval;
    }

    /*
    设置产出数量
    传入 产出数量
    */
    function SetCycleOutput(uint256 _CycleOutput) external onlyOwner {
        CycleOutput = _CycleOutput;
    }

    //---------------------------INQUIRE FUNCTION --------------------------
    /*
    查看MFI用户信息
    返回 可领取数量,未领取数量,领取次数
    */
    function GetUserInformation() public view returns (userCount memory){
        return userData[msg.sender];
    }

    /*
    查看用户总数
    返回 用户数量,用户列表
    */
    function GetUserCount() public view returns (uint256, address[] memory){
        return (userAddress.length, userAddress);
    }

    /*
    计算用户应得奖励数
    */
    function GetReward(address[] memory _users) private view returns (uint256){
        return CycleOutput.div(_users.length);
    }
    //--------------------------- USER FUNCTION --------------------------
    /*
    领取奖励
    */
    function ReceiveAward() external TimeLock {
        bool sper = false;
        require(userData[msg.sender].UserHasReceivedCount > 0, "Without your reward:(");
        MfiAddress.safeTransfer(msg.sender, userData[msg.sender].UserHasReceivedCount);
        userData[msg.sender].UserHasReceivedCount = 0;
        userData[msg.sender].Count++;
        for (uint256 i = 0; i < superUserAddress.length; i++) {
            if (superUserAddress[i] == msg.sender) {
                sper = true;
            }
        }
        emit MFIWithdrawal(msg.sender, userData[msg.sender].UserHasReceivedCount, block.number, sper);
    }
}
