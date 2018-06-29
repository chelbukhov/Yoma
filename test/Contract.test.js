const assert = require ('assert');              // утверждения
const ganache = require ('ganache-cli');        // тестовая сеть
const Web3 = require ('web3');                  // библиотека для подключения к ефириуму
//const web3 = new Web3(ganache.provider());      // настройка провайдера


require('events').EventEmitter.defaultMaxListeners = 0;


const compiledContract = require('../build/Crowdsale.json');
const compiledToken = require('../build/GoldenUnitToken.json');

let accounts;
let contractAddress;
//console.log(Date());



describe('Серия тестов ...', () => {
    let web3 = new Web3(ganache.provider());      // настройка провайдера

    it('Разворачиваем контракт для тестирования...', async () => {

        accounts = await web3.eth.getAccounts();
        //    console.log(accounts);
        //    console.log(await web3.eth.getBalance(accounts[0]));
            // получаем контракт из скомпилированного ранее файла .json
        // разворачиваем его в тестовой сети и отправляем транзакцию
        contract = await new web3.eth.Contract(JSON.parse(compiledContract.interface))
            .deploy({ data: compiledContract.bytecode })
            .send({ from: accounts[0], gas: '6000000'});


        //получаем адрес токена
        const tokenAddress = await contract.methods.token().call();

        //получаем развернутый ранее контракт токена по указанному адресу
        token = await new web3.eth.Contract(
        JSON.parse(compiledToken.interface),
        tokenAddress
        );

    });
    

    it('Адрес контракта...', async () => {
        console.log(await contract.options.address);
    });

    it('Проверка баланса контракта...', async () => {
        let cBalance = web3.utils.fromWei(await web3.eth.getBalance(contract.options.address), 'ether');
        console.log("Balance of contract in Ether: ", cBalance);
        assert(cBalance == 0);
    });

    it('Проверка собственника контракта...', async () => {
        const cOwner = await contract.methods.owner().call();
        assert.equal(accounts[0], cOwner);
    });

    it('Переводим 1 эфир на контракт...', async () => {
        try {
            let funders = await contract.methods.AddBalanceContract().send({
                    from: accounts[0],
                    value: 1*10**18,
                    gas: '1000000'
                });
            assert(true);
        } catch (error) {
            assert(false);
            console.log(error);
        }
    });

    it('Проверка баланса контракта на наличие 1 эфира...', async () => {
        let cBalance = web3.utils.fromWei(await web3.eth.getBalance(contract.options.address), 'ether');
        assert(cBalance == 1);
    });

    it('Проверка поступления токенов на счет отправителя...', async () => {
        let tokenBalance = web3.utils.fromWei(await contract.methods.getBalanceTokens(accounts[0]).call());
        assert(tokenBalance == 30);
        //console.log(tokenBalance);
    });

    it('Адрес токена...', async () => {
        let tokenName = await token.options.address;
        //assert(tokenBalance2 == 30);
        console.log(tokenName);
    });

    it('Имя токена...', async () => {
        let tokenName = await token.methods.name().call();
        //assert(tokenBalance2 == 30);
        console.log(tokenName);
    });

    it('Проверка поступления токенов на счет отправителя через контракт токена...', async () => {
        let tokenBalance2 = web3.utils.fromWei(await token.methods.balanceOf(accounts[0]).call());
        assert(tokenBalance2 == 30);
        //console.log(tokenBalance);
    });

    it('Попытка продать токена контракту - должен отбить...', async () => {
        try {
            let tokenBalance = await contract.methods.purchase(30).send({
                from: accounts[0],
                gas: '1000000'
            });
            assert(false) 
        } catch (error) {
            assert(error);
        }
    });

    it('Установим разрешение принимать токены...', async () => {
        try {
            await contract.methods.startPurchaseTokens().send({
                from: accounts[0],
                gas: '1000000'
            });
            assert(true);
        } catch (error) {
            assert(false);
        }
    });

    it('Проверка баланса account[0]', async () => {
        let cBalance = web3.utils.fromWei(await web3.eth.getBalance(accounts[0]), 'ether');
        assert(cBalance < 99);
        console.log(cBalance);
    });


    it('Попытка продать токена контракту - должен принять...', async () => {
        try {
            let tokenBalance = await contract.methods.purchase(30).send({
                from: accounts[0],
                gas: '1000000'
            });
            assert(true) 
        } catch (error) {
            assert(false);
        }
    });

    it('Проверка баланса account[0]', async () => {
        let cBalance = web3.utils.fromWei(await web3.eth.getBalance(accounts[0]), 'ether');
        assert(cBalance > 99);
        console.log(cBalance);
    });
});











