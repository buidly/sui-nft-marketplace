import { Nft } from "./Nft";

export interface NftWithPrice extends Nft {
  price: string;
}