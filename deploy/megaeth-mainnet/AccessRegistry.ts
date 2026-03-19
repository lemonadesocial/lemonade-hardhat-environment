import { deployFunction } from "../../services/AccessRegistry";

export default deployFunction([
  { role: 'TRUSTED_CLAIMER_ROLE',   account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  { role: 'TRUSTED_OPERATOR_ROLE',  account: '0x69aFB95996970D07eFBCb46Bdc16223fac18FB84',  grant: true },
  { role: 'PAYMENT_ADMIN_ROLE',     account: '0x951292004e8a18955Cb1095CB72Ca6B01d68336E',  grant: true },
]);

