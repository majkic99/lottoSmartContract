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
        const numberOfTicketsToBuy = 100;
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

    });
    it('Drawing 7 numbers', async() =>{
        const lotto = await Lotto.deployed();
        let number = Math.floor(Math.random() * Math.pow(100,9));
        console.log(number);
        number = number.toString();
        await lotto.getRandomNumber(number);
        //TODO this test needs most changing after i manage to integrate kovan and chainlink
        //don't need x

        const numberCounter = await lotto.numberCounter.call();
        assert(numberCounter.toNumber() == 7);

        let resultNumberAt = await lotto.getResultNumbers();
        for (let i = 0; i < 7; i++){
            console.log(resultNumberAt[i].toNumber());
            assert(resultNumberAt[i].toNumber() > 0 && resultNumberAt[i].toNumber() < 40);
        }
    });


    it('Doing calculations and importing stats', async()=>{
        const lotto = await Lotto.deployed();
        const currId = await lotto.currId.call();
        //console.log(currId.toNumber());
        let numberOfWinningTicketsByCorrectNumbers = [0,0,0,0,0,0,0,0];

        let resultNumberAt = await lotto.getResultNumbers();
        for (let i = 1; i < currId.toNumber(); i++){
            let counter = 0;
            const choseNumbers = await lotto.getChosenNumbersByTicketID(i);
            for (let j = 0; j < 7; j++){
                for (let k = 0; k < 7; k++){
                    if (j != k){
                        if (choseNumbers[j].toNumber() == resultNumberAt[k].toNumber()){
                            counter++;
                        }
                    }
                }
            }
            numberOfWinningTicketsByCorrectNumbers[counter]++;
        }
        //console.log('Ispis broja tacnih odgovora')
        let testingCounter = 0;
        for(let i = 0; i < 8; i++){
            console.log('Sa ' + i + ' tacnih brojeva ima : '+ numberOfWinningTicketsByCorrectNumbers[i]);
            testingCounter += numberOfWinningTicketsByCorrectNumbers[i];
        }
        assert(testingCounter == currId-1);

        await lotto.importStats(numberOfWinningTicketsByCorrectNumbers);

        const raffleDone = await lotto.done.call();

        const statsImported = await lotto.statsImportedBool.call();
        assert(raffleDone && statsImported);

        for (let i = 0; i <= 7; i++){
            const numberOfTickets = await lotto.numberOfWinningTicketsByCorrectNumber(i);
            assert(numberOfTickets.toNumber() == numberOfWinningTicketsByCorrectNumbers[i]);

            const winningsPerCorrectNumbers = await lotto.winningAmountByCorrectNumber(i);
            console.log(winningsPerCorrectNumbers.toString());
        }


    });
    it('withdrawing money', async() =>{

        const lotto = await Lotto.deployed();
        const currId = await lotto.currId.call();
        for (let i = 1; i < currId.toNumber(); i++){
            await lotto.payOutTicketByID(i);
        }
        const withdrawnAmount = await lotto.withdrawWinnings();
        console.log(withdrawnAmount);

        const forOrganiser = await lotto.withdrawOrganisersCut();
        console.log(forOrganiser);

        const didOrganiserWitdhraw = await lotto.organisersCutWithdrawn.call();
        assert(didOrganiserWitdhraw);
    })

    //need chainlink connection on kovan for this to work
    //TODO  test what happens when you send more value than ticketPrice, if you're succesfull in withdrawing the rest
    //TODO  buyTickets with wrong Numbers
    //TODO  test what happens with wrong stats
    //TODO  try paying each ticket out, and calculate how much organiser can withdraw and if it's the correct 5%

})

