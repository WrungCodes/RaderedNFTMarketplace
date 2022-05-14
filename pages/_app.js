import "../styles/globals.css";
import { ChakraProvider, extendTheme } from "@chakra-ui/react";
import AuthenticatedLayout from "../layouts/Authenticated";

function MyApp({ Component, pageProps }) {
  return (
    <ChakraProvider
      theme={extendTheme({
        fonts: {
          body: "Epura, system-ui, sans-serif",
        },
      })}
    >
      {/* <AuthenticatedLayout> */}
        <Component {...pageProps} />
      {/* </AuthenticatedLayout> */}
    </ChakraProvider>
  );
}

export default MyApp;
