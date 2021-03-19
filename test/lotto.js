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
    })
})

contract('Lotto', () => {
    it('Buying tickets test', async() => {
        const lotto = await Lotto.deployed();

        for (let i = 0; i < 10; i++){
            var numbers= [];
            for (let j = 0; j < 7; j++){
                do{
                    var x = Math.floor(Math.random() * 39) + 1;

                }while (numbers.includes(x));
                numbers.push(x);
            }

            const ticket = await lotto.buyTicket(numbers, {value : 100000000000000000});
            console.log(ticket);
        }
        const currIdAtStart = await lotto.currId.call();
        assert(currIdAtStart.toNumber() === 11);

    })
})
