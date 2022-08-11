#!/usr/bin/env zx

const apiKey = process.env.API_KEY || await question('API key? ');
const authToken = process.env.AUTH_TOKEN || await question('Auth token? ');
const file = process.env.FILE || await question('File? ');
const methods = process.env.METHODS || await question('Methods (comma-separated)? ');

const abi = await $`jq -c --raw-output '.abi' ${file}`;
const contractAddress = await $`jq -c --raw-output '.address' ${file}`;
const contractName = await $`basename ${file} | cut -d'.' -f1`;

await $`curl https://api.biconomy.io/api/v1/smart-contract/public-api/addContract \
  -H 'apiKey: ${apiKey}' \
  -H 'authToken: ${authToken}' \
  -d abi=${abi} \
  -d contractAddress=${contractAddress} \
  -d contractName=${contractName} \
  -d contractType=SC \
  -d metaTransactionType=TRUSTED_FORWARDER`;

for (const method of methods.split(',')) {
  await $`curl https://api.biconomy.io/api/v1/meta-api/public-api/addMethod \
    -H 'apiKey: ${apiKey}' \
    -H 'authToken: ${authToken}' \
    -d apiType=native \
    -d contractAddress=${contractAddress} \
    -d method=${method} \
    -d methodType=write \
    -d name=${method}`;
}
