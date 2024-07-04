import { deployZkFunction } from "../../services/AccessRegistry";

export default deployZkFunction([
  { role: 'TRUSTED_CLAIMER_ROLE',   account: '0xB25D3d684EAB618B51eE8A3127FBacA6224DaFA9',  grant: true },
  { role: 'TRUSTED_OPERATOR_ROLE',  account: '0xB25D3d684EAB618B51eE8A3127FBacA6224DaFA9',  grant: true },
  { role: 'PAYMENT_ADMIN_ROLE',     account: '0xE88616aB140F29f310E98DD720bcEC8be5D5AC5C',  grant: true },
]);

