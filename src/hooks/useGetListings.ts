import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useNetworkVariable } from "../networkConfig";

export const useGetListings = () => {
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { data, isPending, error, refetch } = useSuiClientQuery("getObject", {
    id: marketplaceObjectId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  const marketplaceFields =
    data?.data?.content?.dataType === "moveObject"
      ? (data.data.content.fields as any)
      : null;

  return {
    data: marketplaceFields?.listings,
    bidsData: marketplaceFields?.bids,
    isPending,
    error,
    refetch,
  };
};
