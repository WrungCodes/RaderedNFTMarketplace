import { Flex, Container, Divider, Stack, Tag, Text } from "@chakra-ui/react";

const SideBar = () => {
  return (
    <Stack w="100%" paddingY={10} spacing="14">
      <Stack spacing={9} >
        <Flex paddingX="10">
          <Tag colorScheme="purple" size={"lg"}>
            <Text isTruncated w="52" fontSize="xs">
              0x29D7d1dd5B6f9C864d9db560D72a247c178aE86B
            </Text>
          </Tag>
        </Flex>
        <Divider />
      </Stack>
      <Stack paddingX="10">
        <Text fontSize="md" fontWeight="medium" colorScheme="purple">
          Main Menu
        </Text>
      </Stack>
    </Stack>
  );
};

export default SideBar;
