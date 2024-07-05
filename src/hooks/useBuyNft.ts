import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";

export const useBuyNft = (onBuy: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const buy = (objectId: string, price: string) => {
    if (!account) {
      return;
    }
    const txb = new TransactionBlock();

    const [coin] = txb.splitCoins(txb.gas, [BigInt(price)]);

    txb.moveCall({
      arguments: [txb.pure(objectId), coin],
      target: `${marketplacePackageId}::nft_marketplace::buy`,
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
              onBuy();
            });
        },
      },
    );
  };

  return buy;
};
