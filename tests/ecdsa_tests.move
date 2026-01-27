#[test_only]
module reclaim::ecdsa_tests {
    use reclaim::ecdsa::ecrecover_to_eth_address;
    use sui::hash::keccak256;
    use std::string::as_bytes;

    // ============================================
    // Test: ecrecover_to_eth_address with valid signature
    // ============================================
    #[test]
    fun test_recover() {
        let endl = b"\n".to_string();

        let provider = b"http".to_string();
        let parameters = b"{\"body\":\"\",\"geoLocation\":\"in\",\"method\":\"GET\",\"responseMatches\":[{\"type\":\"regex\",\"value\":\"_steamid\\\">Steam ID: (?<CLAIM_DATA>.*)</div>\"}],\"responseRedactions\":[{\"jsonPath\":\"\",\"regex\":\"_steamid\\\">Steam ID: (?<CLAIM_DATA>.*)</div>\",\"xPath\":\"id(\\\"responsive_page_template_content\\\")/div[@class=\\\"page_header_ctn\\\"]/div[@class=\\\"page_content\\\"]/div[@class=\\\"youraccount_steamid\\\"]\"}],\"url\":\"https://store.steampowered.com/account/\"}".to_string();
        let context = b"{\"contextAddress\":\"user's address\",\"contextMessage\":\"for acmecorp.com on 1st january\",\"extractedParameters\":{\"CLAIM_DATA\":\"76561199601812329\"},\"providerHash\":\"0xffd5f761e0fb207368d9ebf9689f077352ab5d20ae0a2c23584c2cd90fc1b1bf\"}".to_string();
        let mut claim_info_data = b"".to_string();
        claim_info_data.append(provider);
        claim_info_data.append(endl);
        claim_info_data.append(parameters);
        claim_info_data.append(endl);
        claim_info_data.append(context);

        let hash = keccak256(as_bytes(&claim_info_data));
        assert!(hash == x"d1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd", 0);

        let mut identifier = b"0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string();

        let mut owner = b"0x13239fc6bf3847dfedaf067968141ec0363ca42f".to_string();
        let mut timestamp = b"1712174155".to_string();
        let epoch = b"1".to_string();


        identifier.append(endl);
        owner.append(endl);
        timestamp.append(endl);


        let mut message = b"".to_string();
        message.append(identifier);
        message.append(owner);
        message.append(timestamp);
        message.append(epoch);

        let mut eth_msg = b"\x19Ethereum Signed Message:\n".to_string();

        eth_msg.append(b"122".to_string());
        eth_msg.append(message);

        let msg = as_bytes(&eth_msg);

        let signature = x"2888485f650f8ed02d18e32dd9a1512ca05feb83fc2cbf2df72fd8aa4246c5ee541fa53875c70eb64d3de9143446229a250c7a762202b7cc289ed31b74b31c811c";

        let addr = ecrecover_to_eth_address(signature, *msg);

        /*
        serialized claim: "0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd\n0x13239fc6bf3847dfedaf067968141ec0363ca42f\n1712174155\n1"
        serialized claim length: 7a (122)

        eth message: "19457468657265756d205369676e6564204d6573736167653a0a3132323078643164636663353333386362353838333936653434653634343965386337353062643464373633333263376539343430633932333833333832666365643066640a3078313332333966633662663338343764666564616630363739363831343165633033363363613432660a313731323137343135350a31"
        eth message hash: "c32e57b71247c1aab4b93bb0a2bb373186acc2d5c9bd8dfcd046e1d0553fd421"

        */

        assert!(addr == x"244897572368eadf65bfbc5aec98d8e5443a9072", 0);
    }

    // ============================================
    // Test: keccak256 hash function
    // ============================================
    #[test]
    fun test_keccak256_empty() {
        // keccak256 of empty string
        let empty = vector::empty<u8>();
        let hash = keccak256(&empty);
        // Known keccak256 hash of empty input
        assert!(hash == x"c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470", 0);
    }

    #[test]
    fun test_keccak256_hello() {
        // keccak256 of "hello"
        let data = b"hello";
        let hash = keccak256(&data);
        // Known keccak256 hash of "hello"
        assert!(hash == x"1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8", 0);
    }

    #[test]
    fun test_keccak256_deterministic() {
        // Same input should produce same output
        let data1 = b"test data";
        let data2 = b"test data";
        let hash1 = keccak256(&data1);
        let hash2 = keccak256(&data2);
        assert!(hash1 == hash2, 0);
    }

    #[test]
    fun test_keccak256_different_inputs() {
        // Different inputs should produce different outputs
        let data1 = b"test1";
        let data2 = b"test2";
        let hash1 = keccak256(&data1);
        let hash2 = keccak256(&data2);
        assert!(hash1 != hash2, 0);
    }

    // ============================================
    // Test: ecrecover with v=27 signature format
    // ============================================
    #[test]
    fun test_ecrecover_v27_format() {
        // The signature in test_recover has v=0x1c (28)
        // This test uses a signature with v=27 format
        let endl = b"\n".to_string();

        let mut identifier = b"0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string();
        let mut owner = b"0x13239fc6bf3847dfedaf067968141ec0363ca42f".to_string();
        let mut timestamp = b"1712174155".to_string();
        let epoch = b"1".to_string();

        identifier.append(endl);
        owner.append(endl);
        timestamp.append(endl);

        let mut message = b"".to_string();
        message.append(identifier);
        message.append(owner);
        message.append(timestamp);
        message.append(epoch);

        let mut eth_msg = b"\x19Ethereum Signed Message:\n".to_string();
        eth_msg.append(b"122".to_string());
        eth_msg.append(message);

        let msg = as_bytes(&eth_msg);

        // Same signature but with v=27 (0x1b) instead of v=28 (0x1c)
        let signature = x"2888485f650f8ed02d18e32dd9a1512ca05feb83fc2cbf2df72fd8aa4246c5ee541fa53875c70eb64d3de9143446229a250c7a762202b7cc289ed31b74b31c811b";

        // This should normalize v=27 to v=0 and recover a different address
        let addr = ecrecover_to_eth_address(signature, *msg);
        // The address will be different because v=27 vs v=28 affects recovery
        assert!(vector::length(&addr) == 20, 0);
    }

    // ============================================
    // Test: Ethereum address is 20 bytes
    // ============================================
    #[test]
    fun test_eth_address_length() {
        let endl = b"\n".to_string();

        let mut identifier = b"0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string();
        let mut owner = b"0x13239fc6bf3847dfedaf067968141ec0363ca42f".to_string();
        let mut timestamp = b"1712174155".to_string();
        let epoch = b"1".to_string();

        identifier.append(endl);
        owner.append(endl);
        timestamp.append(endl);

        let mut message = b"".to_string();
        message.append(identifier);
        message.append(owner);
        message.append(timestamp);
        message.append(epoch);

        let mut eth_msg = b"\x19Ethereum Signed Message:\n".to_string();
        eth_msg.append(b"122".to_string());
        eth_msg.append(message);

        let msg = as_bytes(&eth_msg);
        let signature = x"2888485f650f8ed02d18e32dd9a1512ca05feb83fc2cbf2df72fd8aa4246c5ee541fa53875c70eb64d3de9143446229a250c7a762202b7cc289ed31b74b31c811c";

        let addr = ecrecover_to_eth_address(signature, *msg);

        // Ethereum addresses are always 20 bytes
        assert!(vector::length(&addr) == 20, 0);
    }

    // ============================================
    // Test: Signature with v > 35 (EIP-155 format)
    // ============================================
    #[test]
    fun test_ecrecover_eip155_format() {
        // EIP-155 uses v = chain_id * 2 + 35 + recovery_id
        // For chain_id=1 (mainnet), v would be 37 or 38
        let endl = b"\n".to_string();

        let mut identifier = b"0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string();
        let mut owner = b"0x13239fc6bf3847dfedaf067968141ec0363ca42f".to_string();
        let mut timestamp = b"1712174155".to_string();
        let epoch = b"1".to_string();

        identifier.append(endl);
        owner.append(endl);
        timestamp.append(endl);

        let mut message = b"".to_string();
        message.append(identifier);
        message.append(owner);
        message.append(timestamp);
        message.append(epoch);

        let mut eth_msg = b"\x19Ethereum Signed Message:\n".to_string();
        eth_msg.append(b"122".to_string());
        eth_msg.append(message);

        let msg = as_bytes(&eth_msg);

        // Same signature but with v=38 (0x26) - EIP-155 format for chainId=1, recovery=1
        // (38 - 1) % 2 = 1, which matches the original v=28 recovery
        let signature = x"2888485f650f8ed02d18e32dd9a1512ca05feb83fc2cbf2df72fd8aa4246c5ee541fa53875c70eb64d3de9143446229a250c7a762202b7cc289ed31b74b31c8126";

        let addr = ecrecover_to_eth_address(signature, *msg);

        // Should recover the same address as the original v=28 signature
        assert!(addr == x"244897572368eadf65bfbc5aec98d8e5443a9072", 0);
    }
}

