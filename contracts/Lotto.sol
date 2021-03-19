// File: package\src\v0.6\vendor\SafeMathChainlink.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathChainlink {
    /**
      * @dev Returns the addition of two unsigned integers, reverting on
      * overflow.
      *
      * Counterpart to Solidity's `+` operator.
      *
      * Requirements:
      * - Addition cannot overflow.
      */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
      * @dev Returns the subtraction of two unsigned integers, reverting on
      * overflow (when the result is negative).
      *
      * Counterpart to Solidity's `-` operator.
      *
      * Requirements:
      * - Subtraction cannot overflow.
      */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
      * @dev Returns the multiplication of two unsigned integers, reverting on
      * overflow.
      *
      * Counterpart to Solidity's `*` operator.
      *
      * Requirements:
      * - Multiplication cannot overflow.
      */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
      * @dev Returns the integer division of two unsigned integers. Reverts on
      * division by zero. The result is rounded towards zero.
      *
      * Counterpart to Solidity's `/` operator. Note: this function uses a
      * `revert` opcode (which leaves remaining gas untouched) while Solidity
      * uses an invalid opcode to revert (consuming all remaining gas).
      *
      * Requirements:
      * - The divisor cannot be zero.
      */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
      * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
      * Reverts when dividing by zero.
      *
      * Counterpart to Solidity's `%` operator. This function uses a `revert`
      * opcode (which leaves remaining gas untouched) while Solidity uses an
      * invalid opcode to revert (consuming all remaining gas).
      *
      * Requirements:
      * - The divisor cannot be zero.
      */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: package\src\v0.6\interfaces\LinkTokenInterface.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface LinkTokenInterface {
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function approve(address spender, uint256 value) external returns (bool success);
    function balanceOf(address owner) external view returns (uint256 balance);
    function decimals() external view returns (uint8 decimalPlaces);
    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
    function increaseApproval(address spender, uint256 subtractedValue) external;
    function name() external view returns (string memory tokenName);
    function symbol() external view returns (string memory tokenSymbol);
    function totalSupply() external view returns (uint256 totalTokensIssued);
    function transfer(address to, uint256 value) external returns (bool success);
    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// File: package\src\v0.6\VRFRequestIDBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract VRFRequestIDBase {

    /**
     * @notice returns the seed which is actually input to the VRF coordinator
     *
     * @dev To prevent repetition of VRF output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VRF seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
        address _requester, uint256 _nonce)
    internal pure returns (uint256)
    {
        return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
    }

    /**
     * @notice Returns the id for this request
     * @param _keyHash The serviceAgreement ID to be used for this request
     * @param _vRFInputSeed The seed to be passed directly to the VRF
     * @return The id for this request
     *
     * @dev Note that _vRFInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVRFInputSeed
     */
    function makeRequestId(
        bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
    }
}

// File: package\src\v0.6\VRFConsumerBase.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;




/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

    using SafeMathChainlink for uint256;

    /**
     * @notice fulfillRandomness handles the VRF response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VRFConsumerBase expects its subcontracts to have a method with this
     * @dev signature, and will call it once it has verified the proof
     * @dev associated with the randomness. (It is triggered via a call to
     * @dev rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VRF output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

    /**
     * @notice requestRandomness initiates a request for VRF output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * @dev by the Oracle, and verified by the vrfCoordinator.
     *
     * @dev The _keyHash must already be registered with the VRFCoordinator, and
     * @dev the _fee must exceed the fee specified during registration of the
     * @dev _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * @dev compatibility with older versions. It can't *hurt* to mix in some of
     * @dev your own randomness, here, but it's not necessary because the VRF
     * @dev oracle will mix the hash of the block containing your request into the
     * @dev VRF seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of LINK to send with the request
     * @param _seed seed mixed into the input of the VRF.
     *
     * @return requestId unique ID for this request
     *
     * @dev The returned requestId can be used to distinguish responses to
     * @dev concurrent requests. It is passed as the first argument to
     * @dev fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
    {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
        // This is the seed passed to VRFCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VRF cryptographic machinery.
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    LinkTokenInterface immutable internal LINK;
    address immutable private vrfCoordinator;

    // Nonces for each VRF key from which randomness has been requested.
    //
    // Must stay in sync with VRFCoordinator[_keyHash][this]
    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

    /**
     * @param _vrfCoordinator address of VRFCoordinator contract
     * @param _link address of LINK token contract
     *
     * @dev https://docs.chain.link/docs/link-token-contracts
     */
    constructor(address _vrfCoordinator, address _link) public {
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
    }

    // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
    // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
    // the origin of the call
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// File: contract\SuccessfullLotoRandom.sol

pragma solidity 0.6.6;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT


contract Lotto is VRFConsumerBase{
    //for creating random number
    bytes32 internal keyHash;
    //for creating random number
    uint256 internal fee;
    //for creating random number
    uint256 randomResult;
    //counts how many numbers have been drawn already, after this hits 7 no more numbers are added to resultNumbers
    uint8 public numberCounter;

    uint public aggregatePaid;
    //current ticket id
    uint public currId = 1;
    //if true you can pay out tickets
    bool public done;
    //sets true when you've calculated the number of tickets with 0,1,2,3,4,5,6,7 correct numbers;
    bool statsImportedBool;

    bool public organisersCutWithdrawn;

    uint256 public ticketPrice = 0.1 ether;

    address organiser;

    Ticket[] tickets;

    mapping(uint => Ticket) public ticketsByID;

    mapping (address => uint) pendingWithdrawals;

    mapping(uint8 => uint) numberOfWinningTicketsByCorrectNumber;

    mapping(uint8 => uint) winningAmountByCorrectNumber;

    uint8[7] resultNumbers;
    //array of numbers between 1-39
    uint8[] numberDrum;

    event TicketBought(Ticket ticket);

    event NumbersDrawn(uint8[7] resultNumbers);

    event Withdrawal(address winner, uint amount);

    event NumberDrawn(uint8 numberDrawn);

    event Received(address, uint);

    event TicketPaidOut(Ticket);

    event OrganiserWithdrawnFivePercent(address organiser);

    struct Ticket{
        uint id;
        uint8[7] chosenNumbers;
        address owner;
        uint8 numbersCorrect;
        bool paidOut;
    }

    modifier raffleNotStarted(){
        require(!done && numberCounter == 0, "Raffle has ended or numbers are being drawn");
        _;
    }

    modifier allNumbersDrawn(){
        require(numberCounter == 7, "Not yet drawn all 7 numbers");
        _;
    }

    modifier raffleDone(){
        require(done, "Raffle has not finished yet");
        _;
    }

    modifier onlyOrganiser(){
        require(organiser == msg.sender, "Only organiser allowed to call this method!");
        _;
    }

    modifier validNumbers(uint8[7] memory chosenNumbers){
        require(validateNumbers(chosenNumbers), "Chosen numbers are not valid!");
        _;
    }

    modifier statsImported(){
        require(statsImportedBool, "Statistics haven't been calculated and imported yet");
        _;
    }

    modifier organiserCutNotWithdrawn(){
        require(!organisersCutWithdrawn, "You have already withdrawn your cut");
        _;
    }

    constructor()
    VRFConsumerBase(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
        0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
    ) public
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK
        organiser = msg.sender;
        for (uint8 i = 1; i < 40; i++){
            numberDrum.push(i);
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdrawOrganisersCut() external payable onlyOrganiser organiserCutNotWithdrawn raffleDone{
        uint amount = aggregatePaid / 100 * 5;
        organisersCutWithdrawn = true;
        payable(msg.sender).transfer(amount);
        emit OrganiserWithdrawnFivePercent(msg.sender);
    }

    function withdrawLink() external payable onlyOrganiser{
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    function linkBalance() public view onlyOrganiser returns (uint256){
        return LINK.balanceOf(address(this));
    }

    function getResultNumbers() public view returns (uint8[7] memory) {
        return resultNumbers;
    }

    function getChosenNumbersByTicketID(uint id) public view returns(uint8[7] memory){
        return ticketsByID[id].chosenNumbers;
    }

    //ticket must be bought before the raffle started, you enter 7 numbers between 1 and 39 as an array (format [x,x,x,x,x,x,x])
    //returns ticket id, you must remember it to pay it out
    function buyTicket(uint8[7] memory chosenNumbers) public payable raffleNotStarted validNumbers(chosenNumbers) returns (uint){

        require (msg.value >= ticketPrice);

        //if you send more money than the ticket price you can withdraw after the round is over
        //ideas - either enable withdrawals before the raffle has ended or create another mapping and another method for returning overpaid funds
        pendingWithdrawals[msg.sender] += (msg.value - ticketPrice);
        Ticket memory ticket = Ticket(currId++, chosenNumbers, msg.sender, 0, false);
        tickets.push(ticket);
        ticketsByID[ticket.id] = ticket;
        aggregatePaid += ticketPrice;
        emit TicketBought(ticket);
        return ticket.id;
    }

    function importStats(uint[7] memory stats) public onlyOrganiser{
        numberOfWinningTicketsByCorrectNumber[0] = stats[0];
        numberOfWinningTicketsByCorrectNumber[1] = stats[1];
        numberOfWinningTicketsByCorrectNumber[2] = stats[2];
        numberOfWinningTicketsByCorrectNumber[3] = stats[3];
        numberOfWinningTicketsByCorrectNumber[4] = stats[4];
        numberOfWinningTicketsByCorrectNumber[5] = stats[5];
        numberOfWinningTicketsByCorrectNumber[6] = stats[6];
        startRaffle();
    }

    function payOutTicketByID(uint id) public raffleDone{
        Ticket storage ticket = ticketsByID[id];
        require(ticket.owner == msg.sender, "You're not the owner of this ticket");
        uint8 counter = 0;
        for (uint8 i = 0; i < 7; i++){
            for (uint8 j = 0; j < 7; j++){
                if (i != j){
                    if (ticket.chosenNumbers[i] == resultNumbers[j]){
                        counter += 1;
                    }
                }
            }
        }
        ticket.numbersCorrect = counter;
        ticket.paidOut = true;
        pendingWithdrawals[ticket.owner] += winningAmountByCorrectNumber[ticket.numbersCorrect];
        emit TicketPaidOut(ticket);
    }

    function withdrawWinnings() public payable {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function getRandomNumber(uint256 userProvidedSeed) public onlyOrganiser returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");

        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    //Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        if (numberCounter < 7){
            uint8 numberPick = uint8((randomResult % (numberDrum.length - 1 - numberCounter)));
            uint8 resultNumber = numberDrum[numberPick];
            numberDrum[numberPick] = numberDrum[numberDrum.length - 1 - numberCounter];
            resultNumbers[numberCounter++] = resultNumber;
            emit NumberDrawn(resultNumber);
        }
    }

    function startRaffle() internal onlyOrganiser allNumbersDrawn statsImported {


        /*
        //This needs to be off-chain because of undeterminable loop duration (tickets.length -> infinity)
        for (uint i = 0; i < tickets.length; i++){
            uint8 counter = 0;
            for (uint8 j = 0; j < 7; j++){
                for (uint8 k = 0; k < 7; k++){
                    if (i != j){
                        if (tickets[i].chosenNumbers[j] == resultNumbers[k]){
                            counter += 1;
                        }
                    }
                }
                tickets[i].numbersCorrect = counter;
                numberOfWinningTicketsByCorrectNumber[counter] += 1;
            }
        }
        */
        winningAmountByCorrectNumber[0] = 0;
        winningAmountByCorrectNumber[1] = 0;
        winningAmountByCorrectNumber[2] = 0;
        winningAmountByCorrectNumber[3] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[3] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[3]);
        winningAmountByCorrectNumber[4] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[4] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[4]);
        winningAmountByCorrectNumber[5] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[5] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[5]);
        winningAmountByCorrectNumber[6] = (aggregatePaid / 100 * 20) / (numberOfWinningTicketsByCorrectNumber[6] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[6]);
        winningAmountByCorrectNumber[7] = (aggregatePaid / 100 * 45) / (numberOfWinningTicketsByCorrectNumber[7] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[7]);

        /*
        //This has to be implemented separately
        for (uint i = 0; i < tickets.length; i++){
            pendingWithdrawals[tickets[i].owner] += winningAmountByCorrectNumber[tickets[i].numbersCorrect];
        }
        */
        done = true;
        emit NumbersDrawn(resultNumbers);
    }

    function validateNumbers(uint8[7] memory numbers) private pure returns (bool){
        if (numbers.length != 7) return false;

        if (numbers[0] > 39 || numbers[0] < 1) return false;
        if (numbers[1] > 39 || numbers[1] < 1) return false;
        if (numbers[2] > 39 || numbers[2] < 1) return false;
        if (numbers[3] > 39 || numbers[3] < 1) return false;
        if (numbers[4] > 39 || numbers[4] < 1) return false;
        if (numbers[5] > 39 || numbers[5] < 1) return false;
        if (numbers[6] > 39 || numbers[6] < 1) return false;

        if (numbers[0] == numbers[1] || numbers[0] == numbers[2] || numbers[0] == numbers[3] || numbers[0] == numbers[4] || numbers[0] == numbers[5] || numbers[0] == numbers[6] ||
        numbers[1] == numbers[2] || numbers[1] == numbers[3] || numbers[1] == numbers[4] || numbers[1] == numbers[5] || numbers[1] == numbers[6] ||
        numbers[2] == numbers[3] || numbers[2] == numbers[4] || numbers[2] == numbers[5] || numbers[2] == numbers[6] ||
        numbers[3] == numbers[4] || numbers[3] == numbers[5] || numbers[3] == numbers[6] ||
        numbers[4] == numbers[5] || numbers[4] == numbers[6] || numbers[5] == numbers[6] ){
            return false;
        }

        return true;
    }
}
