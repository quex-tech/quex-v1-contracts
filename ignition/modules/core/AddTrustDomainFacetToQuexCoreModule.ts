import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import DeployQuexCoreDiamondModule from "./DeployQuexCoreDiamondModule";
import { TrustDomainFacet__factory } from "../../../typechain";
import DeployTrustDomainFacetModule from "./DeployTrustDomainFacetModule";

const AddTrustDomainFacetToQuexCoreModule = buildModule("AddTrustDomainFacetToQuexCoreModule", (m) => {
    const quexCoreDiamond = m.useModule(DeployQuexCoreDiamondModule).quexCoreDiamond;
    const facet = m.useModule(DeployTrustDomainFacetModule).facet;
    const facetInterface = TrustDomainFacet__factory.createInterface();

    const facetInitializer = m.contract("TrustDomainFacetInitializer");
    const initializerCallData = m.encodeFunctionCall(facetInitializer, "init", []);

    const facetCuts = [
        {
            target: facet,
            action: 0,
            selectors: [
                // add
                facetInterface.getFunction("addPlatformCAKey").selector,
                facetInterface.getFunction("addPCK").selector,
                facetInterface.getFunction("addQE").selector,
                facetInterface.getFunction("addTD").selector,

                // revoke
                facetInterface.getFunction("revokePlatformCA").selector,
                facetInterface.getFunction("revokePCK").selector,
                facetInterface.getFunction("revokeQE").selector,
                facetInterface.getFunction("revokeTD").selector,

                // get
                facetInterface.getFunction("getRootKey").selector,
                facetInterface.getFunction("getPlatformCAKey").selector,
                facetInterface.getFunction("getPCK").selector,
                facetInterface.getFunction("getQE").selector,
                facetInterface.getFunction("getQEAuthority").selector,
                facetInterface.getFunction("getQEId").selector,
                facetInterface.getFunction("getTD").selector,
                facetInterface.getFunction("isTDValid").selector,
                facetInterface.getFunction("getTDSignerAddress").selector,

                // CPU_SVN and TEE_TCB_SVN
                facetInterface.getFunction("allowTeeTcbSvn").selector,
                facetInterface.getFunction("allowCpuSvn").selector,
                facetInterface.getFunction("revokeTeeTcbSvn").selector,
                facetInterface.getFunction("revokeCpuSvn").selector,
                facetInterface.getFunction("isTeeTcbSvnAllowed").selector,
                facetInterface.getFunction("isCpuSvnAllowed").selector,

                // get counters
                facetInterface.getFunction("getPCKCounterByPlatformCA").selector,
                facetInterface.getFunction("getQECounterByProcessorPCK").selector,
                facetInterface.getFunction("getTDCounterByQE").selector,
                facetInterface.getFunction("getTeeTcbSvnTDCounter").selector,
                facetInterface.getFunction("getCpuSvnQECounter").selector,
            ]
        }
    ];

    m.call(quexCoreDiamond, "diamondCut", [facetCuts, facetInitializer, initializerCallData]);
    return { quexCoreDiamond };
});

export default AddTrustDomainFacetToQuexCoreModule;