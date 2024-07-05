import { useSignAndExecuteTransactionBlock, useSuiClient } from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { Nft } from "../types";

export const usePlaceListing = () => {
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const placeListing = () => {
    const txb = new TransactionBlock();

    const nft: Nft = {
      id: '',
      name: '',
      description: '',
      url: '',
      creator: '',
    };

    txb.moveCall({
      arguments: [txb.pure(nft), txb.pure.u64(1000000)],
      target: `${marketplacePackageId}::nft_marketplace::place_listing`,
    });

    signAndExecute(
      {
        transactionBlock: txb,
        options: {
          showEffects: true,
          showObjectChanges: true,
        },
      },
      {
        onSuccess: (tx) => {
          client
            .waitForTransactionBlock({
              digest: tx.digest,
            })
            .then(() => {
              const objectId = tx.effects?.created?.[0]?.reference?.objectId;

              if (objectId) {
                console.log({ objectId });
              }
            });
        },
      },
    );
  };

  return placeListing;
};