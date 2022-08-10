import { deployFunction } from "../../services/AccessRegistry";

const from = '0xFB756b44060e426731e54e9F433c43c75ee90d9f';

export default deployFunction(
  [
    { role: 'TRUSTED_CLAIMER_ROLE',   account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
    { role: 'TRUSTED_OPERATOR_ROLE',  account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  ],
  { from },
);
