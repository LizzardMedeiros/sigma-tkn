const ethereum = {
  "contract_addr": "0x33d6baE099Ae00073F842755C0f49bD427Ea3e93",
  "owner_addr": "0xFAF5BaCf6F7432aB1a72e04D4aA29DbA76b2BBC5",
  ABI: '',
  contractInstance: {},
};

const mouthConverter = n => (
  'hijklabcdefg'.toUpperCase().split('')[n % 12]
);

function createBound() {
  const pre = document.querySelector('#input-pre').value * 1E4;
  const { createBound } = ethereum.contractInstance;
  createBound.sendTransaction(pre, (err, res) => {
    if(err) return;
    console.log(res);
  });
}

function updateFees({target}) {
  const newPreFee = Number(document.querySelector('#update-pre').value) * 1E4 || 0;
  const newPosFee = Number(document.querySelector('#update-pos').value) * 1E4 || 0;
  const birthday = Number(document.querySelector('#portfolio-select').value);
  const { updatePreIndex, updatePosIndex } = ethereum.contractInstance;

  if(birthday === -1) {
    alert('Selecione um título!');
    return;
  }

  if (target.id === 'btn-updatepre') {
    console.log('Pre', newPreFee);
    if(newPreFee === 0) return;
    updatePreIndex.sendTransaction(newPreFee, birthday, (err) => {
      if(err) console.error(err);
    });
  } else if (target.id === 'btn-updatepos') {
    console.log('Pos', newPosFee);
    if(newPosFee === 0) return;
    updatePosIndex.sendTransaction(newPosFee, birthday, (err) => {
      if(err) console.error(err);
    });
  }
}

function sendIft() {
  const to = document.querySelector('#input-transfer-to').value;
  const amount = Number(document.querySelector('#input-transfer-amount').value) * 1E18;
  const birthday = Number(document.querySelector('#portfolio-select').value);
  const { transfer } = ethereum.contractInstance;

  if (birthday === -1) {
    alert('Selecione um título');
    return
  }

  if (amount === 0) {
    alert('Preencha a quantidade');
    return;
  }

  transfer.sendTransaction(to, amount, birthday, (err) => {
    if(err) console.err(err);
  });
}

function withdraw() {
  const amount = document.querySelector('#input-amounteth').value * 1E18;
  const { ownerWithdrawEth } = ethereum.contractInstance;
  ownerWithdrawEth.sendTransaction(amount, (err, res) => {
    if(err) return;
    console.log(res);
  });
}

window.onload = () => {

  document.querySelector('#contract-wallet').innerText = ethereum.contract_addr;
  document.querySelector('#btn-inputpre').addEventListener('click', createBound);
  document.querySelector('#btn-withdraweth').addEventListener('click', withdraw);
  document.querySelector('#btn-updatepre').addEventListener('click', updateFees);
  document.querySelector('#btn-updatepos').addEventListener('click', updateFees);
  document.querySelector('#btn-transfer').addEventListener('click', sendIft);

  if(!window.web3){
    alert('Seu navegador não tem o metamask, ou ele está desativado');
    return;
  }

  window.web3.version.getNetwork((e, NetId) => {
    if(!e){
      if (NetId !== '5777') {
        alert('Rede Ethereum inválida!');
        return;     
      } try {
        window.ethereum.enable();

        window.web3.eth.getGasPrice((e, r) => {
          console.log(r.toNumber());
        });

        fetch('./contracts/IFT.json')
          .then(IFT => {
            IFT.json()
              .then((r) => {
                ethereum.contractInstance = window
                  .web3
                  .eth
                  .contract(r.abi)
                  .at(ethereum.contract_addr);
              })
              .then(() => {
                const wallet = document.querySelector('#wallet');
                wallet.innerText = window.web3.eth.accounts[0];
                window.web3.eth.getBalance(wallet.innerText, (e, r) => {
                  document.querySelector('#eth-balance').innerText = r.toNumber() * 1E-18;
                });

                const {
                  currentMonth,
                  bounds,
                  balanceOf,
                  estimateProfit,
                } = ethereum.contractInstance;

                ethereum.contractInstance._eth.getBalance(ethereum.contract_addr,(err, res) => {
                  if(err) return;
                  const cb = document.querySelector('#contract-balance');
                  cb.innerText = `${(res.toNumber() * 1E-18).toFixed(2)}`;
                })

                currentMonth.call((err, res) => {
                  if(err) return;

                  const portfolio = document.querySelector('#portfolio');
                  const portfolioSelector = document.querySelector('#portfolio-select');
                  portfolio.innerHTML = '';

                  for (let i=0; i < res.toNumber(); i++) {
                    // Monta o portifólio
                    const option = document.createElement('option');
                    const tr = document.createElement('tr');  
                    let td = document.createElement('td');
                    td.innerText = option.innerText = `IFT${mouthConverter(i)}${20 + Math.floor(i / 12)}`;
                    tr.appendChild(td);
                    option.value = i;
                    portfolioSelector.appendChild(option);

                    //Rentabilidade
                    getContractInfo(bounds, i)
                      .then((data) => {
                        let td = document.createElement('td');
                        td.innerText = `${data[0].toNumber() / 1E4}%`;
                        tr.appendChild(td);
                        td = document.createElement('td');
                        td.innerText = `${data[1].toNumber() / 1E4}%`;
                        tr.appendChild(td);
                      });

                    //Posição
                    getContractInfo(balanceOf, wallet.innerText, i)
                      .then((balance) => {
                        const td = document.createElement('td');
                        td.innerText = `${(balance * 1E-18).toFixed(4)} IFT`;
                        tr.appendChild(td);

                        //Rendimento
                        if(balance.toNumber() > 0)
                          getContractInfo(estimateProfit, balance, i)
                          .then((rent) => {
                            let td = document.createElement('td');
                            const profit = (Math.max(rent[0].toNumber(), rent[1].toNumber()) * 1E-18);
                            td.innerText = `${profit.toFixed(4)} ETH`;
                            tr.appendChild(td);
                            td = document.createElement('td');
                            td.innerText = `${(profit).toFixed(4)} ETH`;
                            tr.appendChild(td);
                          });
                        else {
                          let td = document.createElement('td');
                          td.innerText = '0.0000 ETH';
                          tr.appendChild(td);
                          td = document.createElement('td');
                          td.innerText = '0.0000 ETH';
                          tr.appendChild(td);
                        }

                      });

                    portfolio.appendChild(tr);
                  }  
                })
              });

          });
        
      }catch (error){
        console.error(error);
      }
    }
  });
};

async function getContractInfo(info, ...args) {
  return new Promise((resolve, reject) => {
    info.call(...args, (err, res) => {
      if(err) reject(err); 
      resolve(res);
    });
  })
}
