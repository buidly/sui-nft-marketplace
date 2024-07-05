import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useNetworkVariable } from "../networkConfig";

export const useGetListings = () => {
  const marketplacePackageId = useNetworkVariable("listingsObjectId");
  const { data, isPending, error } = useSuiClientQuery("getObject", {
    id: marketplacePackageId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  console.log({ isPending, error, data });
};