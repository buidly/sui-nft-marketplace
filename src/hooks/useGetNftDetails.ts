import { useSuiClientQuery } from "@mysten/dapp-kit";
import { useMemo } from "react";
import { NftWithPrice } from "../types/NftWithPrice";

export const useGetNftDetails = (objectId: string) => {
  const { data, isPending, error } = useSuiClientQuery("getObject", {
    id: objectId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  const nft = useMemo(() => {
    const nftFields =
      data?.data?.content?.dataType === "moveObject"
        ? (data.data.content.fields as any)
        : null;

    if (!nftFields) {
      return null;
    }

    return {
      id: nftFields.id,
      name: nftFields.nft.fields.name,
      description: nftFields.nft.fields.description,
      url: nftFields.nft.fields.url,
      creator: nftFields.nft.fields.creator,
      price: nftFields.price,
    } as NftWithPrice;
  }, [data]);


  return { nft, isPending, error };
};
