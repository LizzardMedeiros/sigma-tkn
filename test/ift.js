const MetaCoin = artifacts.require("IFT");

contract('IFT', function(accounts) {
  it("should put 1000000 MetaCoin in the first account", function() {
    return MetaCoin.deployed().then(function(instance) {
      return instance.balanceOf.call(accounts[0]);
    }).then(function(balance) {
      assert.equal(balance.valueOf(), 1000000, "1000000 wasn't in the first account");
    });
  });
});
