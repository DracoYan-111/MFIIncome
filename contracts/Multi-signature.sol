pragma solidity 0.5.7;
pragma experimental ABIEncoderV2;

contract MultiSig {

    // ============ Events ============

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

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
        uint256 value;
        bytes data;
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
        bytes memory datas = abi.encodeWithSignature("SetUserRewardCount(address[],address[])", _userAddress, _superUserAddress);
        uint256 transactionId = addTransaction(datas);
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
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }
    /**
     * 允许所有者执行已确认的交易
     * @param  transactionId  交易编号。
     */
    function executeTransaction(uint256 transactionId) private ownerExists(msg.sender) confirmed(transactionId, msg.sender) notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (externalCall(destination, txn.value, txn.data.length, txn.data)) {
                emit Execution(transactionId);
               
            } 
			for (uint256 i = 0; i < owners.length; i++) {
                    confirmations[transactionId][owners[i]] = false;
                }
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
    function addTransaction(bytes memory data) internal notNull(destination) returns (uint256){
        uint256 transactionId = 1;
        transactions[transactionId] = Transaction({
        value : 0,
        data : data,
        executed : false
        });
        emit Submission(transactionId);
        return transactionId;
    }

    function externalCall(address destination, uint256 value, uint256 dataLength, bytes memory data) internal returns (bool){
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
            sub(gas, 347100), // 34710 is the value that solidity is currently emittingSolidity
            // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
            // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
            destination,
            value,
            d,
            dataLength, // Size of the input (in bytes) - this is what fixes the padding problem
            x,
            0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }

}
