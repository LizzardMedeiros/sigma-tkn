const ethereum = {
  "contract_addr": "0xC72b242232F8577df0C8cCc090eAE6a5C3d1AFEC",
  "owner_addr": "0x40238f4c1Fa0b8AF7AD928Acf96aD42d1db60E6E",
  ABI: '',
  contractInstance: {},
};

const mouthConverter = (n) => (
  'h,i,j,k,l,a,b,c,d,e,f,g'.toUpperCase().split(',')[n % 12]
);

function createBound() {
  const pre = document.querySelector('#input-pre').value * 1E4;
  const { createBound } = ethereum.contractInstance;
  createBound.sendTransaction(pre, (err, res) => {
    if(err) return;
    console.log(res);
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

  document.querySelector('#btn-inputpre').addEventListener('click', createBound);
  document.querySelector('#btn-withdraweth').addEventListener('click', withdraw);

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
                  portfolio.innerHTML = '';

                  for (let i=0; i < res.toNumber(); i++) {
                    // Monta o portifólio
                    const tr = document.createElement('tr');  
                    let td = document.createElement('td');
                    td.innerText = `IFT${mouthConverter(i)}${20 + Math.floor(i / 12)}`;
                    tr.appendChild(td);

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
                            td.innerText = `${(profit + 1).toFixed(4)} ETH`;
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
        console.log(error);
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
