import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { toast } from "react-toastify";

export const useCancelBid = (onCancelBid: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const listingsObjectId = useNetworkVariable("listingsObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const cancelBid = (bidObjectId: string) => {
    if (!account) {
      return;
    }
    const txb = new TransactionBlock();

    txb.moveCall({
      arguments: [txb.object(listingsObjectId), txb.pure(bidObjectId)],
      target: `${marketplacePackageId}::nft_marketplace::cancel_bid`,
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
              console.log(tx);
              toast.success("Bid canceled with success.", {
                autoClose: 1500,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onCancelBid();
            });
        },
      },
    );
  };

  return cancelBid;
};
