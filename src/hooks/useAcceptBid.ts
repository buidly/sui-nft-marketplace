import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { useNetworkVariable } from "../networkConfig";
import { toast } from "react-toastify";

export const useAcceptBid = (onAcceptBid: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const acceptBid = (bidObjectId: string, objectId: string) => {
    if (!account) {
      return;
    }
    const txb = new TransactionBlock();

    txb.moveCall({
      arguments: [
        txb.object(marketplaceObjectId),
        txb.pure(bidObjectId),
        txb.pure(objectId),
      ],
      target: `${marketplacePackageId}::nft_marketplace::accept_bid`,
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
              toast.success("Bid accepted with success.", {
                autoClose: 3000,
                position: "bottom-right",
                hideProgressBar: true,
                closeOnClick: true,
                pauseOnHover: false,
                draggable: false,
              });
              onAcceptBid();
            });
        },
      },
    );
  };

  return acceptBid;
};
