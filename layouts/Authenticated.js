import { Divider, Grid, GridItem, Flex } from "@chakra-ui/react";
import SideBar from "../components/SideBar";

const AuthenticatedLayout = ({ children }) => {
  return (
    <Grid h="100vh" templateColumns="repeat(5, 1fr)">
      <GridItem colSpan={1} h="100%">
        <Flex h="100%">
          <SideBar />
          <Divider orientation="vertical" />
        </Flex>
      </GridItem>
      <GridItem colSpan={4}>{children}</GridItem>
    </Grid>
  );
};

export default AuthenticatedLayout;
