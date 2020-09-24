// Consts
const YEAR_TO_SEC = (365 * 24 * 60 * 60);
const MONTH_TO_SEC = (30 * 24 * 60 * 60);

const getSeconds = () => Math.floor(Date.now() / 1000);
const timestampNear = (t1, t2) => Math.abs(t1 - t2) <= 10;

const revert = async (func) =>
  await new Promise(async (resolve, reject) => {
    try {
      await func;
    } catch(e) {
      resolve(true);
    } finally {
      reject(false); 
    }  
});

module.exports = {
  YEAR_TO_SEC,
  MONTH_TO_SEC,
  getSeconds,
  timestampNear,
  revert,
};
