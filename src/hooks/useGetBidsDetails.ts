import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useMemo } from "react";
import { Bid } from "../types";

export const useGetBidsDetails = (
  objectsIds: string[],
  nftId: string | undefined,
) => {
  const {
    data: bidsData,
    isPending,
    error,
    fetchStatus,
  } = useSuiClientQuery(
    "multiGetObjects",
    {
      ids: objectsIds,
      options: {
        showContent: true,
        showOwner: true,
      },
    },
    { enabled: nftId !== undefined && objectsIds.length > 0 },
  );

  const bidsNeeded = useMemo(() => {
    if (!bidsData) return undefined;

    return bidsData
      .filter(item => (item?.data?.content as any)?.fields?.name === nftId)
      .flatMap(item => {
        const { fields } = (item?.data?.content as any);
        return fields?.value?.map((bid: any) => {
          return {
            bidId: bid.fields.id.id,
            balance: bid.fields.balance,
            owner: bid.fields.owner,
            nft_id: bid.fields.nft_id,
          };
        });
      });
  }, [bidsData, nftId]);

  return { data: bidsNeeded as Bid[], isPending: isPending && fetchStatus !== "idle", error };
};
