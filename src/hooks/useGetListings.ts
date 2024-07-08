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

  const listingsFields = data?.data?.content?.dataType === "moveObject"
    ? (data.data.content.fields as any)
    : null;

  return { data: listingsFields?.listings, isPending, error };
};