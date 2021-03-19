const Lotto = artifacts.require('Lotto');

contract('Lotto', () => {
    it('Deploy smart contract' , async() => {
        const lotto = await Lotto.deployed();
        console.log(lotto.address);
        assert(lotto.address != '');
    })
})
