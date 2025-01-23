import { ignition } from "hardhat";
import {
    IOraclePool__factory,
    IRequestOraclePool__factory,
    QuexDiamond,
    QuexDiamond__factory
} from "../typechain";
import { FunctionFragment } from "ethers";
import RequestOracleDeployAndConfigurationModule
    from "../ignition/modules/oracles/requests/RequestOracleDeployAndConfigurationModule";

async function run() {
    const { requestsDiamond } = await ignition.deploy(RequestOracleDeployAndConfigurationModule);

    const diamond = QuexDiamond__factory.connect(await requestsDiamond.getAddress(), requestsDiamond.runner);

    await validate_interfaces(diamond);
    // todo: set quex address
    // todo: set treasury
    // todo: set action fee
    // todo: add td address to pool
}

async function validate_interfaces(diamond: QuexDiamond) {
    function validate_function(func: FunctionFragment) {
        if (selectors.includes(func.selector))
            return;
        console.error(`Function ${func.name} (selector ${func.selector}) is not registered in oracle`);
    }

    const selectors = (await diamond.facets.staticCall())
        .reduce((acc: string[], v) => acc.concat(v.selectors), []);

    IOraclePool__factory.createInterface().forEachFunction(x => validate_function(x));
    IRequestOraclePool__factory.createInterface().forEachFunction(x => validate_function(x));
}

run().catch(console.error);