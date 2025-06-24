import { deployZkFunction } from "../../services/AccessRegistry";

export default deployZkFunction([
  { role: 'TRUSTED_CLAIMER_ROLE',   account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  { role: 'TRUSTED_OPERATOR_ROLE',  account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  { role: 'PAYMENT_ADMIN_ROLE',     account: '0xf4a5990Ab778A2c760Be43f3380725BFC4D78b14',  grant: true },
]);
