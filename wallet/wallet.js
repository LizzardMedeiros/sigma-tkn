const ethereum = {
  "contract_addr": "0x08ac3135D855e1Cf44f5d1E39b00c1D3Fdd79742",
  "owner_addr": "0x1570CF5384cB6ba052cb719001dCbAFfB79Ef7bD",
  ABI: '',
  contractInstance: {},
};

function genWallet(walletArray = []) {
  const walletSelector = document.querySelector('#wallet-selector');
  walletSelector.innerHTML = '';
  walletArray.forEach(wallet => {
    const option = document.createElement('option');
    option.value = option.innerText = wallet;
    walletSelector.appendChild(option);
  });
  walletSelector.addEventListener('click', (ev) => {
    console.log(ev.target.value)
    window.web3.eth.getBalance(ev.target.value)
      .then(r => {console.log(r)});
  })
}

window.onload = () => {

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
                genWallet(window.web3.eth.accounts);
                console.log(ethereum.contractInstance);

                ethereum.contractInstance.estimateProfit.call(
                  1000, 0,
                  (err, res) => {
                  console.log(res[0].toNumber())
                })
              });
          });
        

      }catch (error){
        console.log(error);
      }
    }
  });
};