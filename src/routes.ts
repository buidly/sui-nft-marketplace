import { Home, ListNft, NftDetails } from "./pages";

export interface RouteType {
  path: string;
  component: any;
}

export const routeNames = {
  home: "/",
  listNft: "/list-nft",
  nftDetails: "/nft-details",
};

const routes: RouteType[] = [
  {
    path: routeNames.home,
    component: Home,
  },
  {
    path: routeNames.listNft,
    component: ListNft,
  },
  {
    path: routeNames.nftDetails,
    component: NftDetails,
  },
];

export default routes;
