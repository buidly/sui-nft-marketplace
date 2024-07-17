import { useCurrentAccount, useSignAndExecuteTransactionBlock, useSuiClient } from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { toast } from "react-toastify";

export const useCancelListing = (onSuccess: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const cancelListing = (nftId: string, type: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    const nft = txb.moveCall({
      arguments: [
        txb.object(marketplaceObjectId),
        txb.pure(nftId),
      ],
      target: `${marketplacePackageId}::nft_marketplace::cancel_listing`,
      typeArguments: [type]
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
              toast.success("Listing cancelled successfully.", {
                autoClose: 3000,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onSuccess();
            });
        },
        onError: (e) => {
          console.log({ e });
        }
      },
    );
  };

  return cancelListing;
};