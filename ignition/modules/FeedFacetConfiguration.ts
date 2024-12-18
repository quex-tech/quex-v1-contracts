import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import TrustDomainConfiguration from "./TrustDomainConfiguration";
import QuexDiamond from "./QuexDiamond";

export default buildModule("FeedFacetConfiguration", (m) => {
    const quexDiamond = m.useModule(QuexDiamond).quexDiamond;
    const tdAddress = m.useModule(TrustDomainConfiguration).tdAddress;

    const feedWrap = m.contractAt("FeedFacet", quexDiamond);

    m.call(feedWrap, "allowTDForFeed", [tdAddress]);

    return { quexDiamond, tdAddress };
});