import { deployFunction } from "../../services/AccessRegistry";

export default deployFunction([
  { role: 'TRUSTED_CLAIMER_ROLE',   account: '0xB25D3d684EAB618B51eE8A3127FBacA6224DaFA9',  grant: true },
  { role: 'TRUSTED_OPERATOR_ROLE',  account: '0xB25D3d684EAB618B51eE8A3127FBacA6224DaFA9',  grant: true },
]);
