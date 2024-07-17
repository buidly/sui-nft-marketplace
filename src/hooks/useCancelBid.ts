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
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const cancelBid = (bidObjectId: string, nftId: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    const coin = txb.moveCall({
      arguments: [txb.object(marketplaceObjectId), txb.pure(nftId), txb.pure(bidObjectId)],
      target: `${marketplacePackageId}::nft_marketplace::cancel_bid`,
    });

    txb.transferObjects([coin], txb.pure.address(account.address));

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
