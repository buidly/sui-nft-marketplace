import { Home } from "./pages";

export interface RouteType {
  path: string;
  component: any;
}

export const routeNames = {
  home: '/',
};

const routes: RouteType[] = [
  {
    path: routeNames.home,
    component: Home
  },
];

export default routes;
