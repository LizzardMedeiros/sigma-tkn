const IFT = artifacts.require('IFT');
const IFTM = artifacts.require('IFTM');

// Consts
 const YEAR_TO_SEC = (365 * 24 * 60 * 60);
 const MONTH_TO_SEC = (30 * 24 * 60 * 60);

const getSeconds = () => Math.floor(Date.now() / 1000);
const timestampNear = (t1, t2) => Math.abs(t1 - t2) <= 10;

const transactionDetails = ( nonce, to, val ) => ({
  to,
  value: web3.toHex( web3.toWei(val.toString(), 'ether') ),
  nonce,
});

const haveToRevert = async (func) =>
  await new Promise(async (resolve, reject) => {
    try {
      await func;
    } catch(e) {
      resolve(true);
    } finally {
      reject(false); 
    }  
});

contract('IFT', (accounts) => {
  // Testa nome e símbolo
  it('Test name and symbol', async () => {
    const exName = 'Invest Fund Token';
    const exSymbol = 'IFT';
    const { name, symbol } = await IFT.deployed();

    const curName = await name.call();
    const curSymbol = await symbol.call();

    assert.equal(curName.toString(), exName, `Name have to be ${exName}`);
    assert.equal(curSymbol.toString(), exSymbol, `Symbol have to be ${exSymbol}`);
  });

  // Test Bounds
  it('Testing Bounds', async () => {
    const {
      currentMonth,
      lastBoundEmition,
      createBound,
      bounds,
    } = await IFT.deployed();

    // Testando o ambiente
    const exMonth = 0;
    const exLastEmition = 0;
    const firstPreIndex = 10 * 1E3;

    let curMonth = await currentMonth.call();
    let curEmition = await lastBoundEmition.call();
    assert.equal(curMonth.toNumber(), exMonth, 'The initial month have to be 0');
    assert.equal(curEmition.toNumber(), exLastEmition, 'The initial timestamp have to be 0');

    // Testando os bounds

    // Testa se uma conta aleatória pode emitir bounds
    let r = await haveToRevert(createBound.sendTransaction(firstPreIndex, { from: accounts[1]}));
    assert.ok(r, 'Only owner can emit new bounds!');

    // Gera novo bound
    await createBound.sendTransaction(firstPreIndex);
    const { 
      0: boundPreIndex,
      1: boundPosIndex,
      2: boundCurIndex,
      3: boundNextPreIndex,
      4: boundNextPosIndex,
    } = await bounds.call(curMonth);

    // Testa se as taxas estão devidamente registradas
    assert.equal(boundPreIndex.toNumber(), firstPreIndex, `Bound preindex have to be ${firstPreIndex}`);
    assert.equal(boundPosIndex.toNumber(), 0, `Bound posindex can not have to be greater than 0`);
    assert.equal(boundCurIndex.toNumber(), 0, `Bound curindex can not have to be greater than 0`);
    
    const now = getSeconds();
    const nextYear = now + YEAR_TO_SEC;
    const nextMonth = now + MONTH_TO_SEC;

    // Testa atualizações
    assert.ok(timestampNear(boundNextPreIndex.toNumber(), nextYear), 'The preindex deadline have to be 1 year');
    assert.ok(timestampNear(boundNextPosIndex.toNumber(), nextMonth), 'The posindex deadline have to be 1 month');

    curMonth = await currentMonth.call();
    curEmition = await lastBoundEmition.call();

    assert.equal(curMonth.toNumber(), exMonth + 1, 'The current month have to be 1');
    assert.ok(timestampNear(curEmition.toNumber(), now) ,`O timestamp inicial precisa ser ${now}`);

    // Testa se é possível emitir outro bound
    r = await haveToRevert(createBound.call(firstPreIndex));
    assert.ok(r, 'New emition is forbiden!');
  });

  it('Testing profit calculation (with mock)', async () => {
    const meta = IFTM.deployed();
    const {
      symbol,
      currentMonth,
      estimateProfit,
      lastBoundEmition,
      createBound,
      updatePreIndex,
      updatePosIndex,
      addMonth,
    } = await meta;

    // Test if contract was deployed

    const exSymbol = 'IFTM';
    const curSymbol = await symbol.call();
    assert.equal(curSymbol.toString(), exSymbol, `Symbol have to be ${exSymbol}`);
    
    // Testing Pre index

    //Gera um bound com taxa aleatória
    const firstPreIndex = Math.ceil(Math.random() * 100) * 1E2; 

    // Gera novo bound
    await createBound.sendTransaction(firstPreIndex);
    const curLastBoundEmition = await lastBoundEmition.call();
    assert.ok(curLastBoundEmition.toNumber() > 0, `Bound have to be created.`);

    await addMonth.sendTransaction(12);
    await updatePreIndex.sendTransaction(0, 0); // Kills bound[0]

    let curMonth = await currentMonth.call();
    assert.equal(curMonth.toNumber(), 13, 'Current mouth have to be 13');

    // makes 10 random amount tests
    for (let i=0; i<10; i++) {
      const amount = Math.ceil(Math.random() * 1E10);
      const profit = await estimateProfit.call(amount, 0);
      const exProfit = Math.floor(amount + (amount * firstPreIndex / 1E5));
      assert.equal(profit.toNumber(), exProfit, `Total have to be ${profit.toNumber()}`);
    }

    // Testing Pos index

    await createBound.sendTransaction(10 * 1E3);
    const nextBoundEmition = await lastBoundEmition.call();
    assert.ok(curLastBoundEmition.toNumber() < nextBoundEmition.toNumber(), `Bound have to be created.`);

    curMonth = await currentMonth.call();
    const newBoundMonth = curMonth - 1;

    const firstPosIndex = (30 * 1E3);
    await updatePosIndex.sendTransaction(firstPosIndex, newBoundMonth);
    await addMonth.sendTransaction(12);
    await updatePreIndex.sendTransaction(0, newBoundMonth); // Kills bound[0]

    const amount = 100;
    const profit = await estimateProfit.call(amount, newBoundMonth);
    const exProfit = Math.floor(amount + (amount * firstPosIndex / 1E5));
    assert.equal(profit.toNumber(), exProfit, `Total have to be ${exProfit}`);
  });

  it('Testing ETH transactions', () => {

  });

  it('Testing IFT transactions', () => {

  });

});