const Lotto = artifacts.require('Lotto');

contract('Lotto', () => {
    it('Starting values on deployment test' , async() => {
        const lotto = await Lotto.deployed();
        //console.log(lotto.address);
        assert(lotto.address != '');
        const currIdAtStart = await lotto.currId.call();
        assert(currIdAtStart.toNumber() === 1);

        const aggregatePaid = await lotto.aggregatePaid.call();
        assert(aggregatePaid.toNumber() === 0);

        const done = await lotto.done.call();
        assert(!done);

        const numberCounter = await lotto.numberCounter.call();
        assert(numberCounter.toNumber() === 0);

        const resultNumbers = await lotto.getResultNumbers();
        for (let i = 0; i < 7; i++){
            assert(resultNumbers[i].toNumber() === 0);
        }
    });
    it('Buying tickets test', async() => {
        const lotto = await Lotto.deployed();
        const numberOfTicketsToBuy = 10;
        for (let i = 0; i < numberOfTicketsToBuy; i++){
            var numbers= [];
            for (let j = 0; j < 7; j++){
                do{
                    var x = Math.floor(Math.random() * 39) + 1;
                }while (numbers.includes(x));
                numbers.push(x);
            }

            const ticket = await lotto.buyTicket(numbers, {value : 100000000000000000});

            const numbersSavedObject = await lotto.getChosenNumbersByTicketID(i+1);
            for (let k = 0; k < 7; k++){
                assert(numbers[k] = numbersSavedObject[k].toNumber());
            }
        }
        const currIdAtStart = await lotto.currId.call();
        assert(currIdAtStart.toNumber() === numberOfTicketsToBuy+1);

    })
    //need chainlink connection on kovan for this to work
    //TODO  call getRandomNumber(i) - let i from 1 to 7
    //TODO  do calculations - for each getChosenNumbersByTicketID(i) - let i from 1 to currID.call()
    //TODO  importStats( int[7] ) , array is derived from doing calculations from last step
    //TODO  test what happens when you send more value than ticketPrice, if you're succesfull in withdrawing the rest
    //TODO  buyTickets with wrong Numbers
    //TODO  test what happens with wrong stats
    //TODO  try paying each ticket out, and calculate how much organiser can withdraw and if it's the correct 5%

})

