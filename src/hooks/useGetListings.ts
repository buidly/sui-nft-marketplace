import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useNetworkVariable } from "../networkConfig";

export const useGetListings = () => {
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { data: marketplaceData, isPending: marketplacePending, error: marketplaceError } = useSuiClientQuery("getObject", {
    id: marketplaceObjectId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  const marketplaceFields =
    marketplaceData?.data?.content?.dataType === "moveObject"
      ? (marketplaceData.data.content.fields as any)
      : null;

  const { data: listings, isPending: listingsPending, error: listingsError, refetch: refetchListings } = useSuiClientQuery("getDynamicFields", {
    parentId: marketplaceFields?.listings?.fields?.id?.id,
  }, { enabled: marketplaceFields != null });

  const { data: bids, isPending: bidsPending, error: bidsError, refetch: refetchBids } = useSuiClientQuery("getDynamicFields", {
    parentId: marketplaceFields?.bids?.fields?.id?.id,
  }, { enabled: marketplaceFields != null });

  return {
    listings: listings?.data?.map(obj => obj.objectId) ?? [],
    bids: bids?.data?.map(obj => obj.objectId) ?? [],
    isPending: marketplacePending || listingsPending || bidsPending,
    error: marketplaceError || listingsError || bidsError,
    refetchListings,
    refetchBids,
  };
};
