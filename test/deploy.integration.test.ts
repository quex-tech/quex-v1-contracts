import { expect } from "chai";
import { ethers } from "hardhat";
import { run as runCoreDeploy } from "../scripts/quex_core_complete_deploy";
import { run as runRequestDeploy } from "../scripts/request_oracle_complete_deploy";

describe("Deploy full Quex stack", function () {
  this.timeout(300_000);

  it("should deploy Quex core and request oracle", async () => {
    try {
      const [deployer] = await ethers.getSigners();
      const deployerAddress = await deployer.getAddress();

      const quexNetworkConfig = {
        core: {
          quexFee: 1000n,
          quexFulfillingGasCost: 100n,
          treasuryAddress: deployerAddress,
          managerAddress: deployerAddress
        },
        request: {
          actionFee: 250n,
          treasuryAddress: deployerAddress,
          managerAddress: deployerAddress
        }
      };

      console.log("Deploying core...");
      await runCoreDeploy(quexNetworkConfig);

      console.log("Deploying request oracle...");
      await runRequestDeploy(quexNetworkConfig);

    } catch (err) {
      console.error("Deployment failed", err);
      throw err;
    }
  });
});
