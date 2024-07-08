import { useCurrentAccount, useSignAndExecuteTransactionBlock, useSuiClient } from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { toast } from "react-toastify";

export const useCancelListing = (onCancelled: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const listingsObjectId = useNetworkVariable("listingsObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const cancelListing = (listingObjectId: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    txb.moveCall({
      arguments: [
        txb.object(listingsObjectId),
        txb.pure(listingObjectId),
      ],
      target: `${marketplacePackageId}::nft_marketplace::cancel_listing`,
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
              toast.success("Listing cancelled successfully.", {
                autoClose: 3000,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onCancelled();
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