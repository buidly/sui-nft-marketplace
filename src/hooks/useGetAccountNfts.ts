

import { useCurrentAccount, useSuiClientQuery } from "@mysten/dapp-kit";
import { Nft } from '../types';

export const useGetAccountNfts = () => {
  const account = useCurrentAccount();

  const { data, isPending, error } = useSuiClientQuery(
    "getOwnedObjects",
    {
      owner: account?.address as string, options: {
        showContent: true,
        showOwner: true,
      },
    },
    { enabled: !!account }
  );

  return {
    nfts: data?.data?.filter(obj => {
      const type = obj.data?.content?.dataType === "moveObject"
        ? (obj.data.content.type as any)
        : null;
      return type?.includes('TestnetNFT') ?? false;
    })
      .map(obj => {
        const nft = obj.data;
        const nftFields =
          nft?.content?.dataType === "moveObject"
            ? (nft.content.fields as any)
            : null;

        return {
          id: nft?.objectId,
          name: nftFields?.name ?? '',
          description: nftFields?.description ?? '',
          url: nftFields?.url ?? '',
          creator: nftFields?.creator ?? '',
          type: (nft?.content as any)?.type ?? '',
        } as Nft;
      }) ?? [],
    isPending,
    error
  };
};
