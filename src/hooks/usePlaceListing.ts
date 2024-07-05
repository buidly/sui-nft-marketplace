import { useCurrentAccount, useSignAndExecuteTransactionBlock, useSuiClient } from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { MIST_PER_SUI } from "@mysten/sui.js/utils";

export const usePlaceListing = (onListed: (id: string) => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const listingsObjectId = useNetworkVariable("listingsObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const placeListing = (objectId: string, price: number) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    txb.moveCall({
      arguments: [
        txb.object(listingsObjectId),
        txb.pure(objectId),
        txb.pure.u64(price * Number(MIST_PER_SUI))
      ],
      target: `${marketplacePackageId}::nft_marketplace::place_listing`,
    });

    txb.setGasBudget(100000000);

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
        onError: (e) => {
          console.log({ e });
        }
      },
    );
  };

  return placeListing;
};