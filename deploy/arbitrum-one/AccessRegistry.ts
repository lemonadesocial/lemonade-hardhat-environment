import { deployFunction } from "../../services/AccessRegistry";

export default deployFunction([
  { role: 'TRUSTED_CLAIMER_ROLE',         account: '0xB25D3d684EAB618B51eE8A3127FBacA6224DaFA9',  grant: true },
  { role: 'TRUSTED_OPERATOR_ROLE',        account: '0xB25D3d684EAB618B51eE8A3127FBacA6224DaFA9',  grant: true },
  { role: 'FESTIVAL_HEADS_OPERATOR_ROLE', account: '0xB32bF33D8Bf52d9f526CdF64EDD2f337Ac23f8C1',  grant: true },
]);
