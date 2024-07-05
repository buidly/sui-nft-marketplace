import { Home, NftDetails } from "./pages";

export interface RouteType {
  path: string;
  component: any;
}

export const routeNames = {
  home: "/",
  nftDetails: "/details/:objectId",
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
];

export default routes;
