import { useSuiClientQuery } from "@mysten/dapp-kit";
import { SuiObjectResponse } from "@mysten/sui.js/client";

export const useGetNftDetails = (objectId: string) => {
  const { data, isPending, error } = useSuiClientQuery("getObject", {
    id: objectId,
    options: {
      showContent: true,
      showOwner: true,
    },
  });

  // const dataNft = data as SuiObjectResponse;

  return { data, isPending, error };
};
