pragma experimental ABIEncoderV2;

interface mfiincone{
    function SetUserRewardCount(address[] calldata _userAddress, address[] calldata _superUserAddress) external  returns (bool);
}
contract MultiSig {

    // ============ Events ============

    // ============ Constants ============

    uint256 constant public MAX_OWNER_COUNT = 50;
    address constant ADDRESS_ZERO = address(0x0);
    address destination;

    // ============ Storage ============

    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;
    uint256 public ctionId;

    // ============ Structs ============

    struct Transaction {
        address[] userAddress;
        address[] superUserAddress;
        bool executed;
    }

    // ============ Modifiers ============
    modifier onlyWallet() {
        /* solium-disable-next-line error-reason */
        require(msg.sender == address(this));
        _;
    }
    modifier ownerDoesNotExist(address owner) {
        /* solium-disable-next-line error-reason */
        require(!isOwner[owner]);
        _;
    }
    modifier ownerExists(address owner) {
        /* solium-disable-next-line error-reason */
        require(isOwner[owner], "ownerExists!!!!!!!!!!!");
        _;
    }
    modifier transactionExists(uint256 transactionId) {
        /* solium-disable-next-line error-reason */
        require(destination != ADDRESS_ZERO, "transactionExists@@@@@@@@@@@@");
        _;
    }
    modifier confirmed(uint256 transactionId, address owner) {
        /* solium-disable-next-line error-reason */
        require(confirmations[transactionId][owner]);
        _;
    }
    modifier notConfirmed(uint256 transactionId, address owner) {
        /* solium-disable-next-line error-reason */
        require(!confirmations[transactionId][owner], "notConfirmed#######");
        _;
    }
    modifier notExecuted(uint256 transactionId) {
        /* solium-disable-next-line error-reason */
        require(!transactions[transactionId].executed);
        _;
    }
    modifier notNull(address _address) {
        /* solium-disable-next-line error-reason */
        require(_address != ADDRESS_ZERO);
        _;
    }
    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        /* solium-disable-next-line error-reason */
        require(
            ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0
        );
        _;
    }

    // ============ Constructor ============
    /**
     * 合同构建者设置初始所有者和所需的确认数量。
     *
     * @param  _owners    初始所有者列表(数组)
     * @param  _required  所需确定的数量
     */
    constructor(address[] memory _owners, uint256 _required, address mfidestination) public validRequirement(_owners.length, _required){
        for (uint256 i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != ADDRESS_ZERO);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        destination = mfidestination;
    }

    /**
     *允许所有者提交并确认交易
     */
    function submitTransaction(address[] memory _userAddress, address[] memory _superUserAddress) public returns (uint256){
        uint256 transactionId = addTransaction(_userAddress,_superUserAddress);
        ctionId = transactionId;
        confirmTransaction(transactionId);
        return transactionId;
    }

    /**
     * 允许所有者确认交易.
     *
     * @param  transactionId  Transaction ID.交易编号。
     */
    function confirmTransaction(uint256 transactionId) public ownerExists(msg.sender) transactionExists(transactionId) notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;

        executeTransaction(transactionId);
    }
    /**
     * 允许所有者执行已确认的交易
     * @param  transactionId  交易编号。
     */
    function executeTransaction(uint256 transactionId) private ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {

        if (isConfirmed(transactionId)) {
            for (uint256 i = 0; i < owners.length; i++) {
                confirmations[transactionId][owners[i]] = false;
            }
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            mfiincone(destination).SetUserRewardCount(txn.userAddress,txn.superUserAddress);

        }
    }

    // ============ Getter Functions ============

    /**
     * 返回交易的确认状态。
     *
     * @param  transactionId  Transaction ID.交易编号
     * @return                Confirmation status.确认状态。
     */
    function isConfirmed(uint256 transactionId) public view returns (bool){
        uint256 count = 0;
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
            if (count == required) {
                return true;
            }
        }
    }
    /*
   添加交易
   传入 交易目标地址  交易以太币价值 交易数据有效载荷 交易编号
   */
    function addTransaction(address[] memory _userAddress, address[] memory _superUserAddress) internal notNull(destination) returns (uint256){
        uint256 transactionId = 1;
        transactions[transactionId] = Transaction({
        userAddress:_userAddress,
        superUserAddress:_superUserAddress,
        executed : false
        });
        return transactionId;
    }

}
