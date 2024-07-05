import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useNetworkVariable } from "../networkConfig";

export const useGetListings = () => {
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const { data, isPending, error } = useSuiClientQuery("getObject", {
    id: "0x3ab9896e631bbcfec4a6bed0e87a8a8a6a4becdaef03eb1cf4d501fe48e358e3",
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  console.log({ isPending, error, data });
};