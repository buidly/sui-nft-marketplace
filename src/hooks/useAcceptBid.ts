import {
  useCurrentAccount,
  useSignAndExecuteTransactionBlock,
  useSuiClient,
} from "@mysten/dapp-kit";
import { TransactionBlock } from "@mysten/sui.js/transactions";
import { toast } from "react-toastify";
import { useNetworkVariable } from "../networkConfig";

export const useAcceptBid = (onAcceptBid: () => void) => {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const marketplacePackageId = useNetworkVariable("marketplacePackageId");
  const marketplaceObjectId = useNetworkVariable("marketplaceObjectId");
  const { mutate: signAndExecute } = useSignAndExecuteTransactionBlock();

  const acceptBid = (bidObjectId: string, nftId: string, type: string) => {
    if (!account) {
      return;
    }

    const txb = new TransactionBlock();

    const coin = txb.moveCall({
      arguments: [
        txb.object(marketplaceObjectId),
        txb.pure(nftId),
        txb.pure(bidObjectId),
      ],
      target: `${marketplacePackageId}::nft_marketplace::accept_bid`,
      typeArguments: [type],
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
              toast.success("Bid accepted successfully.", {
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
        onError: (err) => {
          console.log({ err });
        }
      },
    );
  };

  return acceptBid;
};
