
pragma solidity 0.6.6;

import "./VRFConsumerBase.sol";
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

/**
 * @dev Contract for playing Lotto game with lots of players, where organiser
 * is guaranteed to take only 5 percent.
 *
 * Uses VRFConsumerBase and chainlink integration for random number generation.
 */
contract Lotto is VRFConsumerBase{

    using SafeMathChainlink for uint;

    //for creating random number
    bytes32 internal keyHash; //32 bytes
    //for creating random number
    uint256 internal fee; //32 bytes
    //for creating random number
    uint256 randomResult; //32 bytes
    //sum of all tickets paid for => (currId - 1) * ticketPrice
    uint public aggregatePaid; //32 byte
    //current ticket id
    uint public currId = 1; //32 byte
    uint256 public ticketPrice = 0.1 ether; //32 byte
    //counts how many numbers have been drawn already, after this hits 7 no more numbers are added to resultNumbers
    uint8 public numberCounter; //1 byte
    //if true you can pay out tickets
    bool public done; //1 byte
    //sets true when you've calculated the number of tickets with 0,1,2,3,4,5,6,7 correct numbers;
    bool public statsImportedBool; //1 byte
    //this exists so organiser can only withdraw once
    bool public organisersCutWithdrawn; //1 byte

    address organiser; //20 byte
    //first starts with 7 zeroes, later is filled with 7 different numbers via 7 calls to RandomNumber
    uint8[7] resultNumbers;
    //array of numbers between 1-39
    uint8[] numberDrum;

    Ticket[] tickets;

    mapping (address => uint) pendingWithdrawals;

    mapping(uint8 => uint) public numberOfWinningTicketsByCorrectNumber;

    mapping(uint8 => uint) public winningAmountByCorrectNumber;

    event TicketBought(Ticket ticket);

    event NumbersDrawn(uint8[7] resultNumbers);

    event Withdrawal(address winner, uint amount);

    event NumberDrawn(uint8 numberDrawn);

    event TicketPaidOut(Ticket);

    event OrganiserWithdrawnFivePercent(address organiser);

    struct Ticket{
        uint8 numbersCorrect; //1 byte
        bool paidOut; //1 byte
        address owner; // 20 bytes
        uint8[7] chosenNumbers; //7 bytes - array starts separately
        uint id; //32 bytes
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

    /**
      * @dev Organiser calls this after everything is done so he can withdraw 5%
      *
      * Requirements:
      * - raffle has to be done
      * - only organiser can call it
      * - organiser has to be calling it for the first time
      */
    function withdrawOrganisersCut() external payable onlyOrganiser organiserCutNotWithdrawn raffleDone{
        uint amount = aggregatePaid / 100 * 5;
        organisersCutWithdrawn = true;
        payable(msg.sender).transfer(amount);
        emit OrganiserWithdrawnFivePercent(msg.sender);
    }

    function withdrawLink() external payable onlyOrganiser{
        require(LINK.transfer(msg.sender, LINK.balanceOf(address(this))), "Unable to transfer");
    }

    /**
      * @dev Anyone can call this before the first number has been drawn (first RandomNumber call)
      *
      * Requirements:
      * - value to be higher than ticket price (extra can be withdrawn immediately
      * @param chosenNumbers - has to be an array of 7 valid numbers (between 1-39, all different)
      * - numberCounter must be zero
      */
    function buyTicket(uint8[7] memory chosenNumbers) public payable raffleNotStarted validNumbers(chosenNumbers) returns (uint){
        require (msg.value >= ticketPrice);
        pendingWithdrawals[msg.sender] = pendingWithdrawals[msg.sender].add(msg.value - ticketPrice);
        Ticket memory ticket = Ticket(0, false, msg.sender, chosenNumbers, currId);
        currId = currId.add(1);
        tickets.push(ticket);
        aggregatePaid = aggregatePaid.add(ticketPrice);
        emit TicketBought(ticket);
        return ticket.id;
    }
    /**
      * @dev Only organiser can call this, it's called after the calculations are done off-chain.
      * Calls startRaffle which calculates how much is a winning ticket worth.
      * Requirements:
      * @param stats - array of integers equal to or greater than 0
      * - values of array combined have to be equal to currId - 1
      */
    function importStats(uint[8] memory stats) public onlyOrganiser{
        uint counter = 0;
        for (uint8 i = 0; i < 8; i++){
            counter = counter.add(stats[i]);
        }
        require(counter == currId - 1, "Stats aren't adding up");
        numberOfWinningTicketsByCorrectNumber[0] = stats[0];
        numberOfWinningTicketsByCorrectNumber[1] = stats[1];
        numberOfWinningTicketsByCorrectNumber[2] = stats[2];
        numberOfWinningTicketsByCorrectNumber[3] = stats[3];
        numberOfWinningTicketsByCorrectNumber[4] = stats[4];
        numberOfWinningTicketsByCorrectNumber[5] = stats[5];
        numberOfWinningTicketsByCorrectNumber[6] = stats[6];
        numberOfWinningTicketsByCorrectNumber[7] = stats[7];
        statsImportedBool = true;
        startRaffle();
    }
    /**
      * @dev Can be called after raffle has ended
      * Ticket can be redeemed only by it's owner, after redeeming winnings will be put on withdraw balance
      * Requirements:
      * @param id - id of ticket you want to be reedemed
      */
    function payOutTicketByID(uint id) public raffleDone{
        Ticket storage ticket = tickets[id-1];
        require(ticket.owner == msg.sender, "You're not the owner of this ticket");
        uint8 counter = 0;
        for (uint8 i = 0; i < 7; i++){
            for (uint8 j = 0; j < 7; j++){
                if (ticket.chosenNumbers[i] == resultNumbers[j]){
                        counter += 1;
                        break;
                }
            }
        }
        ticket.numbersCorrect = counter;
        ticket.paidOut = true;
        pendingWithdrawals[ticket.owner] = pendingWithdrawals[ticket.owner].add(winningAmountByCorrectNumber[ticket.numbersCorrect]);
        emit TicketPaidOut(ticket);
    }
    /**
      * @dev Sender withdraws any winnings that he had (either from redeeming tickets or from overpaying for a ticket)
      */
    function withdrawWinnings() public payable {
        uint amount = pendingWithdrawals[msg.sender];
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
    /**
      * @dev Organiser calls this to draw 7 numbers, it costs 0.1 LINK per call
      * @param userProvidedSeed - any random number
      */
    function getRandomNumber(uint256 userProvidedSeed) public onlyOrganiser returns (bytes32 requestId) {
        //changed for testing without chainlink, result number at the end is equal to userProvidedSeed
        fulfillRandomness(keccak256(abi.encodePacked("ok")), userProvidedSeed);
        return keccak256(abi.encodePacked("ok"));
        /*
        require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee, userProvidedSeed);
        */
    }

    function getResultNumbers() public view returns (uint8[7] memory) {
        return resultNumbers;
    }

    function getChosenNumbersByTicketID(uint id) public view returns(uint8[7] memory){
        return tickets[id-1].chosenNumbers;
    }

    //Callback function used by VRF Coordinator
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        uint forDivision = 100;
        for (uint8 i = 0; i < 7; i++){
            //in first loop pickingNumber is 0-39, in second 0-38, third 0-37...
            uint8 pickingNumber = uint8((randomResult / forDivision % 1000) % (40 - i));
            forDivision = forDivision*100;
            uint8 resultNumber = numberDrum[pickingNumber];
            numberDrum[pickingNumber] = numberDrum[38-i];
            resultNumbers[numberCounter++] = resultNumber;
            emit NumberDrawn(resultNumber);
        }
    }

    function startRaffle() internal onlyOrganiser allNumbersDrawn statsImported {
        winningAmountByCorrectNumber[0] = 0;
        winningAmountByCorrectNumber[1] = 0;
        winningAmountByCorrectNumber[2] = 0;
        winningAmountByCorrectNumber[3] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[3] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[3]);
        winningAmountByCorrectNumber[4] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[4] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[4]);
        winningAmountByCorrectNumber[5] = (aggregatePaid / 100 * 10) / (numberOfWinningTicketsByCorrectNumber[5] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[5]);
        winningAmountByCorrectNumber[6] = (aggregatePaid / 100 * 20) / (numberOfWinningTicketsByCorrectNumber[6] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[6]);
        winningAmountByCorrectNumber[7] = (aggregatePaid / 100 * 45) / (numberOfWinningTicketsByCorrectNumber[7] == 0 ? 1: numberOfWinningTicketsByCorrectNumber[7]);
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

        if (numbers[0] == numbers[1] || numbers[0] == numbers[2] || numbers[0] == numbers[3] ||
            numbers[0] == numbers[4] || numbers[0] == numbers[5] || numbers[0] == numbers[6] ||
            numbers[1] == numbers[2] || numbers[1] == numbers[3] || numbers[1] == numbers[4] ||
            numbers[1] == numbers[5] || numbers[1] == numbers[6] || numbers[2] == numbers[3] ||
            numbers[2] == numbers[4] || numbers[2] == numbers[5] || numbers[2] == numbers[6] ||
            numbers[3] == numbers[4] || numbers[3] == numbers[5] || numbers[3] == numbers[6] ||
            numbers[4] == numbers[5] || numbers[4] == numbers[6] || numbers[5] == numbers[6] )
        {
                return false;
        }

        return true;
    }
}
