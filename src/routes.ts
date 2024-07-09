import { Home, NftDetails } from "./pages";
import { NftListing } from "./pages/NftListing/NftListing";

export interface RouteType {
  path: string;
  component: any;
}

export const routeNames = {
  home: "/",
  nftDetails: "/details/:objectId",
  placeListing: "listing"
};

const routes: RouteType[] = [
  {
    path: routeNames.home,
    component: Home,
  },
  {
    path: routeNames.nftDetails,
    component: NftDetails,
  },
  {
    path: routeNames.placeListing,
    component: NftListing,
  },
];

export default routes;
