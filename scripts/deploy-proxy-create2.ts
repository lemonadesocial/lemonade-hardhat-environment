import { ethers } from 'hardhat';
import assert from 'assert';

import { stringToBytes32 } from "../test/utils";

const { FACTORY, NAME, SALT, ARGS } = process.env;

async function main() {
  assert.ok(FACTORY && SALT && NAME);

  const salt = stringToBytes32(SALT);
  const genericFactory = await ethers.getContractAt("GenericFactory", FACTORY);

  const ToBeDeployedFactory = await ethers.getContractFactory(NAME);
  const bytecode = ToBeDeployedFactory.bytecode;

  const predictedAddress = await genericFactory.predictAddress(
    bytecode,
    salt
  );

  console.log("Predicted address:", predictedAddress);

  await genericFactory.createContract(bytecode, salt);

  const deployedContract = await ethers.getContractAt(NAME, predictedAddress);

  const initializeTx = await deployedContract.initialize(...(ARGS ? JSON.parse(ARGS) : []));
  await initializeTx.wait();

  console.log("Contract initialized successfully.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
