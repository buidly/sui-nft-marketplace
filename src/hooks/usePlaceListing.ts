import { useCurrentAccount, useSignAndExecuteTransactionBlock, useSuiClient } from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";

export const usePlaceListing = (onListed: (id: string) => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const placeListing = (objectId: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    txb.moveCall({
      arguments: [txb.pure(objectId), txb.pure.u64(1000000)],
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
              console.log({ tx });
              const objectId = tx.effects?.created?.[0]?.reference?.objectId;

              if (objectId) {
                onListed(objectId);
              }
            });
        },
      },
    );
  };

  return placeListing;
};