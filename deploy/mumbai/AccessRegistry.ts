import { deployFunction } from "../../services/AccessRegistry";

export default deployFunction([
  { role: 'TRUSTED_CLAIMER_ROLE',         account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  { role: 'TRUSTED_OPERATOR_ROLE',        account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  { role: 'FESTIVAL_HEADS_OPERATOR_ROLE', account: '0xfb756b44060e426731e54e9f433c43c75ee90d9f',  grant: true },
]);
