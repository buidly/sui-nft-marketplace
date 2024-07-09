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

  const { data: dynamicFieldsData, isPending: dynamicFieldsPending, error: dynamicFieldsError } = useSuiClientQuery("getDynamicFields", {
    parentId: objectId,
  });

  const dynamicFieldObjectId = dynamicFieldsData?.data?.[0]?.objectId;

  const { data: nftData, isPending: nftPending, error: nftError } = useSuiClientQuery("multiGetObjects", {
    ids: [dynamicFieldObjectId!!],
    options: {
      showContent: true,
      showOwner: true,
    },
  }, { enabled: dynamicFieldsData?.data?.[0] != null });


  const nft = useMemo(() => {
    const nftFields =
      nftData?.[0]?.data?.content?.dataType === "moveObject"
        ? (nftData[0].data.content.fields as any)
        : null;

    const objectFields =
      objectData?.data?.content?.dataType === "moveObject"
        ? (objectData.data.content.fields as any)
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
      price: objectFields.price,
      owner: objectFields.owner,
    } as NftWithPrice;
  }, [objectData, nftData]);


  return {
    nft,
    isPending: objectPending || dynamicFieldsPending || nftPending,
    error: objectError || dynamicFieldsError || nftError
  };
};
