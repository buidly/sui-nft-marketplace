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
      .map((item: any) => {
        const { fields } = item.data.content;
        return {
          bidId: item.data.objectId,
          balance: fields.balance,
          owner: fields.owner,
          nft_id: fields.nft_id,
        };
      })
      .filter((item) => item.nft_id === nftId);
  }, [bidsData, nftId]);

  return { data: bidsNeeded as Bid[], isPending, error };
};
