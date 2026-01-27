#[test_only]
module reclaim::reclaim_tests {
  use reclaim::reclaim;
  use sui::test_scenario;

  // ============================================
  // Test: Full proof verification flow (happy path)
  // ============================================
  #[test]
  fun test_reclaim() {
    let owner = @0xC0FFEE;
    let user1 = @0xA1;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(user1);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s,
                                      test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, owner);
    {
      let mut witnesses = vector<vector<u8>>[];
      let witness_address = x"244897572368eadf65bfbc5aec98d8e5443a9072";
      witnesses.push_back(witness_address);

      let requisite_witnesses_for_claim_create = 1_u128;

      let mut manager =
          test_scenario::take_shared<reclaim::ReclaimManager>(scenario);

      reclaim::add_new_epoch(&mut manager, witnesses,
                             requisite_witnesses_for_claim_create,
                             test_scenario::ctx(scenario));

      test_scenario::return_shared(manager);
    };


   test_scenario::next_tx(scenario, user1);
    {
     let ctx = test_scenario::ctx(scenario);

      let claim_info = reclaim::create_claim_info(
         b"http".to_string(),
         b"{\"body\":\"\",\"geoLocation\":\"in\",\"method\":\"GET\",\"responseMatches\":[{\"type\":\"regex\",\"value\":\"_steamid\\\">Steam ID: (?<CLAIM_DATA>.*)</div>\"}],\"responseRedactions\":[{\"jsonPath\":\"\",\"regex\":\"_steamid\\\">Steam ID: (?<CLAIM_DATA>.*)</div>\",\"xPath\":\"id(\\\"responsive_page_template_content\\\")/div[@class=\\\"page_header_ctn\\\"]/div[@class=\\\"page_content\\\"]/div[@class=\\\"youraccount_steamid\\\"]\"}],\"url\":\"https://store.steampowered.com/account/\"}".to_string(),
         b"{\"contextAddress\":\"user's address\",\"contextMessage\":\"for acmecorp.com on 1st january\",\"extractedParameters\":{\"CLAIM_DATA\":\"76561199601812329\"},\"providerHash\":\"0xffd5f761e0fb207368d9ebf9689f077352ab5d20ae0a2c23584c2cd90fc1b1bf\"}".to_string()
      );

      let complete_claim_data = reclaim::create_claim_data(
        b"0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string(),
        b"0x13239fc6bf3847dfedaf067968141ec0363ca42f".to_string(),
        b"1".to_string(),
        b"1712174155".to_string(),
      );

      let mut signatures = vector<vector<u8>>[];
      let signature = x"2888485f650f8ed02d18e32dd9a1512ca05feb83fc2cbf2df72fd8aa4246c5ee541fa53875c70eb64d3de9143446229a250c7a762202b7cc289ed31b74b31c811c";
      signatures.push_back(signature);

      let signed_claim = reclaim::create_signed_claim(
        complete_claim_data,
        signatures
      );

      reclaim::create_proof(claim_info, signed_claim, ctx);
    };

  test_scenario::next_tx(scenario, user1);
    {
      let manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let proof = test_scenario::take_shared<reclaim::Proof>(scenario);
      let ctx = test_scenario::ctx(scenario);
      let signers = reclaim::verify_proof(&manager, &proof, ctx);
      assert!(signers == vector[x"244897572368eadf65bfbc5aec98d8e5443a9072"], 0);

      test_scenario::return_shared(manager);
      test_scenario::return_shared(proof);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: bytes_to_hex helper function
  // ============================================
  #[test]
  fun test_bytes_to_hex() {
    // Test empty vector
    let empty = vector::empty<u8>();
    assert!(reclaim::bytes_to_hex(&empty) == b"".to_string(), 0);

    // Test single byte
    let single = vector[0x00u8];
    assert!(reclaim::bytes_to_hex(&single) == b"00".to_string(), 1);

    // Test 0xff
    let ff = vector[0xffu8];
    assert!(reclaim::bytes_to_hex(&ff) == b"ff".to_string(), 2);

    // Test multiple bytes
    let multi = vector[0x12u8, 0x34u8, 0xabu8, 0xcdu8];
    assert!(reclaim::bytes_to_hex(&multi) == b"1234abcd".to_string(), 3);

    // Test known hash value
    let hash = x"d1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd";
    assert!(reclaim::bytes_to_hex(&hash) == b"d1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string(), 4);
  }

  // ============================================
  // Test: get_provider_from_proof
  // ============================================
  #[test]
  fun test_get_provider_from_proof() {
    let user1 = @0xA1;
    let mut scenario_val = test_scenario::begin(user1);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, user1);
    {
      let ctx = test_scenario::ctx(scenario);
      let claim_info = reclaim::create_claim_info(
        b"test_provider".to_string(),
        b"test_params".to_string(),
        b"test_context".to_string()
      );

      let complete_claim_data = reclaim::create_claim_data(
        b"0x1234".to_string(),
        b"0xowner".to_string(),
        b"1".to_string(),
        b"12345".to_string(),
      );

      let signed_claim = reclaim::create_signed_claim(
        complete_claim_data,
        vector::empty()
      );

      reclaim::create_proof(claim_info, signed_claim, ctx);
    };

    test_scenario::next_tx(scenario, user1);
    {
      let proof = test_scenario::take_shared<reclaim::Proof>(scenario);
      let provider = reclaim::get_provider_from_proof(&proof);
      assert!(provider == b"test_provider".to_string(), 0);
      test_scenario::return_shared(proof);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: create_dapp
  // ============================================
  #[test]
  fun test_create_dapp() {
    let owner = @0xC0FFEE;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let dapp_id = b"my_dapp_id";
      reclaim::create_dapp(&mut manager, dapp_id, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: create_dapp with different users
  // ============================================
  #[test]
  fun test_create_dapp_different_users() {
    let owner = @0xC0FFEE;
    let user1 = @0xA1;
    let user2 = @0xA2;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    // User1 creates a dapp
    test_scenario::next_tx(scenario, user1);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      reclaim::create_dapp(&mut manager, b"shared_dapp_id", test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    // User2 creates a dapp with same id - should succeed (different sender = different hash)
    test_scenario::next_tx(scenario, user2);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      reclaim::create_dapp(&mut manager, b"shared_dapp_id", test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: Non-owner cannot add epoch (should fail)
  // ============================================
  #[test]
  #[expected_failure(abort_code = 0)]
  fun test_add_epoch_non_owner_fails() {
    let owner = @0xC0FFEE;
    let non_owner = @0xBAD;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    // Non-owner tries to add epoch - should fail
    test_scenario::next_tx(scenario, non_owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"244897572368eadf65bfbc5aec98d8e5443a9072"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: Duplicate dapp creation should fail
  // ============================================
  #[test]
  #[expected_failure(abort_code = 0)]
  fun test_create_duplicate_dapp_fails() {
    let owner = @0xC0FFEE;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      reclaim::create_dapp(&mut manager, b"my_dapp_id", test_scenario::ctx(scenario));
      // Try to create the same dapp again - should fail
      reclaim::create_dapp(&mut manager, b"my_dapp_id", test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: Verify proof with no signatures should fail
  // ============================================
  #[test]
  #[expected_failure(abort_code = 0)]
  fun test_verify_proof_no_signatures_fails() {
    let owner = @0xC0FFEE;
    let user1 = @0xA1;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"244897572368eadf65bfbc5aec98d8e5443a9072"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::next_tx(scenario, user1);
    {
      let ctx = test_scenario::ctx(scenario);
      let claim_info = reclaim::create_claim_info(
        b"http".to_string(),
        b"params".to_string(),
        b"context".to_string()
      );

      let complete_claim_data = reclaim::create_claim_data(
        b"0x1234".to_string(),
        b"0xowner".to_string(),
        b"1".to_string(),
        b"12345".to_string(),
      );

      // Empty signatures
      let signed_claim = reclaim::create_signed_claim(
        complete_claim_data,
        vector::empty()
      );

      reclaim::create_proof(claim_info, signed_claim, ctx);
    };

    test_scenario::next_tx(scenario, user1);
    {
      let manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let proof = test_scenario::take_shared<reclaim::Proof>(scenario);
      let ctx = test_scenario::ctx(scenario);
      // This should fail - no signatures
      let _signers = reclaim::verify_proof(&manager, &proof, ctx);
      test_scenario::return_shared(manager);
      test_scenario::return_shared(proof);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: Verify proof with mismatched claim info hash should fail
  // ============================================
  #[test]
  #[expected_failure(abort_code = 1)]
  fun test_verify_proof_mismatched_hash_fails() {
    let owner = @0xC0FFEE;
    let user1 = @0xA1;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"244897572368eadf65bfbc5aec98d8e5443a9072"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::next_tx(scenario, user1);
    {
      let ctx = test_scenario::ctx(scenario);
      // Create claim_info with different data than what the identifier hash represents
      let claim_info = reclaim::create_claim_info(
        b"wrong_provider".to_string(),
        b"wrong_params".to_string(),
        b"wrong_context".to_string()
      );

      // This identifier doesn't match the claim_info above
      let complete_claim_data = reclaim::create_claim_data(
        b"0xd1dcfc5338cb588396e44e6449e8c750bd4d76332c7e9440c92383382fced0fd".to_string(),
        b"0x13239fc6bf3847dfedaf067968141ec0363ca42f".to_string(),
        b"1".to_string(),
        b"1712174155".to_string(),
      );

      let mut signatures = vector<vector<u8>>[];
      let signature = x"2888485f650f8ed02d18e32dd9a1512ca05feb83fc2cbf2df72fd8aa4246c5ee541fa53875c70eb64d3de9143446229a250c7a762202b7cc289ed31b74b31c811c";
      signatures.push_back(signature);

      let signed_claim = reclaim::create_signed_claim(
        complete_claim_data,
        signatures
      );

      reclaim::create_proof(claim_info, signed_claim, ctx);
    };

    test_scenario::next_tx(scenario, user1);
    {
      let manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let proof = test_scenario::take_shared<reclaim::Proof>(scenario);
      let ctx = test_scenario::ctx(scenario);
      // Should fail with abort_code 1 - hash mismatch
      let _signers = reclaim::verify_proof(&manager, &proof, ctx);
      test_scenario::return_shared(manager);
      test_scenario::return_shared(proof);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: fetch_epoch
  // ============================================
  #[test]
  fun test_fetch_epoch() {
    let owner = @0xC0FFEE;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"aabbccdd11223344556677889900aabbccddeeff"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::next_tx(scenario, owner);
    {
      let manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let _epoch = reclaim::fetch_epoch(&manager);
      // If we got here without abort, fetch_epoch works
      test_scenario::return_shared(manager);
    };

    test_scenario::end(scenario_val);
  }

  // ============================================
  // Test: Multiple epochs
  // ============================================
  #[test]
  fun test_multiple_epochs() {
    let owner = @0xC0FFEE;
    let epoch_duration_s = 1_000_000_u32;

    let mut scenario_val = test_scenario::begin(owner);
    let scenario = &mut scenario_val;

    test_scenario::next_tx(scenario, owner);
    {
      reclaim::create_reclaim_manager(epoch_duration_s, test_scenario::ctx(scenario));
    };

    // Add first epoch
    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"1111111111111111111111111111111111111111"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    // Add second epoch
    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"2222222222222222222222222222222222222222"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    // Add third epoch
    test_scenario::next_tx(scenario, owner);
    {
      let mut manager = test_scenario::take_shared<reclaim::ReclaimManager>(scenario);
      let witnesses = vector[x"3333333333333333333333333333333333333333"];
      reclaim::add_new_epoch(&mut manager, witnesses, 1, test_scenario::ctx(scenario));
      test_scenario::return_shared(manager);
    };

    test_scenario::end(scenario_val);
  }
}