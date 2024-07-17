import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useMemo } from "react";
import { NftWithPrice } from "../types/NftWithPrice";

export const useGetNftDetails = (objectId: string) => {
  const { data: objectData, isPending: objectPending, error: objectError } = useSuiClientQuery("getObject", {
    id: objectId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  const objectFields =
    objectData?.data?.content?.dataType === "moveObject"
      ? (objectData.data.content.fields as any)
      : null;

  const { data: nftData, isPending: nftPending, error: nftError } = useSuiClientQuery("getObject", {
    id: objectFields?.value?.fields?.nft_id,
    options: {
      showContent: true,
      showOwner: true,
    },
  }, { enabled: objectFields?.value?.fields != null });

  const nft = useMemo(() => {
    const nftFields =
      nftData?.data?.content?.dataType === "moveObject"
        ? (nftData.data.content.fields as any)
        : null;

    if (!nftFields || !objectFields) {
      return null;
    }

    return {
      id: nftFields.id.id,
      name: nftFields.name,
      description: nftFields.description,
      url: nftFields.url,
      creator: nftFields.creator,
      price: objectFields.value.fields.price,
      owner: objectFields.value.fields.owner,
      type: (nftData?.data?.content as any)?.type ?? ''
    } as NftWithPrice;
  }, [objectData, nftData]);


  return {
    nft,
    isPending: objectPending || nftPending,
    error: objectError || nftError
  };
};
