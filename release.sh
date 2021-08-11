#!/usr/bin/env bash
set -e

while getopts v: flag
do
    case "${flag}" in
        v) version=${OPTARG};;
    esac
done

echo $version

./build.sh -c ./config/prod.json

rm -rf ./package
mkdir -p package

echo "{
  \"name\": \"@maplelabs/stake-locker\",
  \"version\": \"${version}\",
  \"description\": \"Stake Locker Artifacts and ABIs\",
  \"author\": \"Maple Labs\",
  \"license\": \"AGPLv3\",
  \"repository\": {
    \"type\": \"git\",
    \"url\": \"https://github.com/maple-labs/stake-locker.git\"
  },
  \"bugs\": {
    \"url\": \"https://github.com/maple-labs/stake-locker/issues\"
  },
  \"homepage\": \"https://github.com/maple-labs/stake-locker\"
}" > package/package.json

mkdir -p package/artifacts
mkdir -p package/abis

cat ./out/dapp.sol.json | jq '.contracts | ."contracts/StakeLockerFactory.sol" | .StakeLockerFactory' > package/artifacts/StakeLockerFactory.json
cat ./out/dapp.sol.json | jq '.contracts | ."contracts/StakeLockerFactory.sol" | .StakeLockerFactory | .abi' > package/abis/StakeLockerFactory.json
cat ./out/dapp.sol.json | jq '.contracts | ."contracts/StakeLocker.sol" | .StakeLocker' > package/artifacts/StakeLocker.json
cat ./out/dapp.sol.json | jq '.contracts | ."contracts/StakeLocker.sol" | .StakeLocker | .abi' > package/abis/StakeLocker.json

npm publish ./package --access public

rm -rf ./package
