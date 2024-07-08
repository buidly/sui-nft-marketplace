import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { toast } from "react-toastify";

export const useBuyNft = (onBuy: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const listingsObjectId = useNetworkVariable("listingsObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const buy = (objectId: string, price: string) => {
    if (!account) {
      return;
    }
    const txb = new TransactionBlock();

    const [coin] = txb.splitCoins(txb.gas, [BigInt(price)]);

    const nft = txb.moveCall({
      arguments: [txb.object(listingsObjectId), txb.pure(objectId), coin],
      target: `${marketplacePackageId}::nft_marketplace::buy`,
    });

    txb.transferObjects([nft], txb.pure.address(account.address));

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
              toast.success("NFT bought successfully.", {
                autoClose: 3000,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onBuy();
            });
        },
      },
    );
  };

  return buy;
};
