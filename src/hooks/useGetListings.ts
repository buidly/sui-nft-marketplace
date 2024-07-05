import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useNetworkVariable } from "../networkConfig";

export const useGetListings = () => {
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const { data, isPending, error } = useSuiClientQuery("getOwnedObjects", {
    owner: marketplacePackageId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  console.log({ isPending, error, data });
};