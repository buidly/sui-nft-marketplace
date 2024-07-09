import { MIST_PER_SUI } from "@mysten/sui.js/utils";
import BigNumber from "bignumber.js";

export const priceDenom = (price: string) => {
  return new BigNumber(price ?? 0).dividedBy(MIST_PER_SUI.toString());
};
